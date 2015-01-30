require 'spec_helper'
require 'efg/data_migrator'

class MyData
  def self.migrate!
  end
end

describe "DataMigrator" do

  let(:logger) { double.as_null_object }
  let(:migrator) { EFG::DataMigrator.new(path: File.dirname(__FILE__) + "/../fixtures/data_migrations", logger: logger) }

  it "finds all migrations in the specified directory" do
    assert_equal ['20100101120000_migrate_some_data.rb'], migrator.migrations.map(&:filename)
    assert migrator.migrations.first.is_a?(EFG::DataMigration)
  end

  context "#run" do
    it "runs all migrations" do
      expect(MyData).to receive(:migrate!)
      migrator.run
    end

    it "runs each migration in a transaction" do
      DataMigrationRecord.stub(:create!)
      expect(ActiveRecord::Base.connection).to receive(:transaction).and_yield
      expect(MyData).to receive(:migrate!)
      migrator.run
    end

    it "records a data migration on success" do
      expect(DataMigrationRecord).to receive(:create!).with(version: "20100101120000")
      migrator.run
    end
  end

  context "#due" do
    it "returns all migrations except those which have already been run" do
      assert_equal ['20100101120000_migrate_some_data.rb'], migrator.due.map(&:filename)
      migrator.run
      assert_equal [], migrator.due.map(&:filename)
    end
  end

end
