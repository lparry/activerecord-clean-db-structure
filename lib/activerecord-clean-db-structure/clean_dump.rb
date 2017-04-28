module ActiveRecordCleanDbStructure
  class CleanDump
    attr_reader :dump
    def initialize(dump)
      @dump = dump
    end

    def run
      # Remove trailing whitespace
      dump.gsub!(/[ \t]+$/, '')
      dump.gsub!(/\A\n/, '')
      dump.gsub!(/\n\n\z/, "\n")

      # Remove version-specific output
      dump.gsub!(/^-- Dumped.*/, '')
      dump.gsub!(/^SET row_security = off;$/, '') # 9.5
      dump.gsub!(/^SET idle_in_transaction_session_timeout = 0;$/, '') # 9.6

      # Remove pg_stat_statements extension (its not relevant to the code)
      dump.gsub!(/^CREATE EXTENSION IF NOT EXISTS pg_stat_statements.*/, '')
      dump.gsub!(/^COMMENT ON EXTENSION pg_stat_statements.*/, '')
      dump.gsub!(/^-- Name: (EXTENSION )?pg_stat_statements;.*/, '')

      # Remove useless, version-specific parts of comments
      dump.gsub!(/^-- (.*); Schema: (public|-); Owner: -.*/, '-- \1')

      # Remove useless comment lines
      dump.gsub!(/^--$/, '')

      # Remove inherited tables
      inherited_tables_regexp = /-- Name: ([\w_]+); Type: TABLE\n\n[^;]+?INHERITS \([\w_]+\);/m
      inherited_tables = dump.scan(inherited_tables_regexp).map(&:first)
      dump.gsub!(inherited_tables_regexp, '')
      inherited_tables.each do |inherited_table|
        dump.gsub!(/ALTER TABLE ONLY #{inherited_table}[^;]+;/, '')
      end

      # Remove whitespace between schema migration INSERTS to make editing easier
      dump.gsub!(/^(INSERT INTO schema_migrations .*)\n\n/, "\\1\n")

      # Reduce 2+ lines of whitespace to one line of whitespace
      dump.gsub!(/\n{2,}/m, "\n\n")
    end
  end
end
