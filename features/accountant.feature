Feature: Accountant

  Background:
    Given a default accountant

  Scenario: Missing source
    Given a sourceless accountant
    Then I cannot save

  Scenario: Invalid source (missing class)
    Given the accountant:
      """
        class InvalidSourceAccountant < Morty::Accountant
          source :missing
        end
      """
     Then the accountant is invalid

  Scenario: Invalid source (missing id)
    Given the accountant:
      """
        class SourceExample
        end

        class InvalidSourceExampleAccountant < Morty::Accountant
          source :source_example
        end
      """
     Then the accountant is invalid

  Scenario: Multiple sources
    Given the configuration:
      """
        class Source1; end
        class Source2; end

        @accountant.source = :source1
        @accountant.source = :source2
      """
     Then the accountant is invalid

  Scenario: Future start date
    Given the configuration:
      """
        @accountant.start_date = Date.current + 1
      """
     Then the accountant is invalid
