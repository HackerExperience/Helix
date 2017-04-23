%{
  configs: [
    %{
      name: "improvement",
      files: %{
        included: ["lib", "test"]
      },
      check_for_updates: false,
      strict: true,
      color: true,
      checks: [
        {Credo.Check.Design.AliasUsage},
        {Credo.Check.Design.TagFIXME},
        {Credo.Check.Design.TagTODO},

        {Credo.Check.Readability.ModuleDoc},
        {Credo.Check.Readability.StringSigils}
      ]
    },
    %{
      name: "default",
      files: %{
        included: ["lib", "test"]
      },
      check_for_updates: false,
      strict: true,
      color: true,
      checks: [
        {Credo.Check.Consistency.ExceptionNames},
        {Credo.Check.Consistency.LineEndings},
        {Credo.Check.Consistency.MultiAliasImportRequireUse},
        {Credo.Check.Consistency.ParameterPatternMatching},
        {Credo.Check.Consistency.SpaceAroundOperators},
        {Credo.Check.Consistency.SpaceInParentheses},
        {Credo.Check.Consistency.TabsOrSpaces},

        {Credo.Check.Design.AliasUsage, false},
        {Credo.Check.Design.DuplicatedCode, false},
        {Credo.Check.Design.TagFIXME, false},
        {Credo.Check.Design.TagTODO, false},

        {Credo.Check.Readability.FunctionNames},
        {Credo.Check.Readability.LargeNumbers},
        {Credo.Check.Readability.MaxLineLength, max_length: 80, ignore_definitions: true, ignore_specs: true, ignore_strings: true},
        {Credo.Check.Readability.ModuleAttributeNames},
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Readability.ModuleNames},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs},
        {Credo.Check.Readability.ParenthesesInCondition},
        {Credo.Check.Readability.PredicateFunctionNames},
        {Credo.Check.Readability.PreferImplicitTry},
        {Credo.Check.Readability.StringSigils, false},
        {Credo.Check.Readability.RedundantBlankLines},
        {Credo.Check.Readability.TrailingBlankLine, false},
        {Credo.Check.Readability.TrailingWhiteSpace},
        {Credo.Check.Readability.VariableNames},

        {Credo.Check.Refactor.DoubleBooleanNegation, false},
        {Credo.Check.Refactor.ABCSize, false},
        {Credo.Check.Refactor.CondStatements},
        # TODO: Check if this is a good metric and tune the max complexity
        {Credo.Check.Refactor.CyclomaticComplexity},
        {Credo.Check.Refactor.FunctionArity, max_arity: 6, ignore_defp: true},
        {Credo.Check.Refactor.MatchInCondition},
        {Credo.Check.Refactor.NegatedConditionsInUnless},
        {Credo.Check.Refactor.NegatedConditionsWithElse},
        {Credo.Check.Refactor.Nesting, max_nesting: 4},
        # This is a duplicate of cyclomatic complexity
        {Credo.Check.Refactor.PerceivedComplexity, false},
        {Credo.Check.Refactor.PipeChainStart, false},
        {Credo.Check.Refactor.UnlessWithElse},

        {Credo.Check.Warning.BoolOperationOnSameValues},
        {Credo.Check.Warning.IExPry},
        {Credo.Check.Warning.IoInspect},
        {Credo.Check.Warning.OperationOnSameValues},
        {Credo.Check.Warning.OperationWithConstantResult},
        {Credo.Check.Warning.UnusedEnumOperation},
        {Credo.Check.Warning.UnusedFileOperation},
        {Credo.Check.Warning.UnusedKeywordOperation},
        {Credo.Check.Warning.UnusedListOperation},
        {Credo.Check.Warning.UnusedPathOperation},
        {Credo.Check.Warning.UnusedRegexOperation},
        {Credo.Check.Warning.UnusedStringOperation},
        {Credo.Check.Warning.UnusedTupleOperation},

        # Deprecated
        {Credo.Check.Readability.Specs, false},
        {Credo.Check.Warning.NameRedeclarationByAssignment, false},
        {Credo.Check.Warning.NameRedeclarationByCase, false},
        {Credo.Check.Warning.NameRedeclarationByDef, false},
        {Credo.Check.Warning.NameRedeclarationByFn, false}
      ]
    }
  ]
}
