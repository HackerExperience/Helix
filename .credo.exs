%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["apps/*/lib", "app/*/test"]
      },
      check_for_updates: false,
      strict: true,
      requires: ["apps/hell/lib/credo/"],
      checks: [
        {Credo.Check.Consistency.ExceptionNames, priority: :normal},
        {Credo.Check.Consistency.LineEndings, priority: :low},
        {Credo.Check.Consistency.ParameterPatternMatching, priority: :normal},
        {Credo.Check.Consistency.SpaceAroundOperators, priority: :high},
        {Credo.Check.Consistency.SpaceInParentheses, priority: :high},
        {Credo.Check.Consistency.TabsOrSpaces, priority: :high},

        {Credo.Check.Design.AliasUsage, priority: :low},
        {Credo.Check.Design.DuplicatedCode, false},
        {Credo.Check.Design.TagFIXME, priority: :normal},
        {Credo.Check.Design.TagTODO, priority: :low},

        {Credo.Check.Readability.FunctionNames, priority: :high},
        {Credo.Check.Readability.LargeNumbers, priority: :low},
        {Credo.Check.Readability.MaxLineLength, max_length: 80, ignore_definitions: true, ignore_specs: true, priority: :low},
        {Credo.Check.Readability.ModuleAttributeNames, priority: :high},
        {Credo.Check.Readability.ModuleDoc, priority: :low},
        {Credo.Check.Readability.ModuleNames, priority: :high},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, priority: :low},
        {Credo.Check.Readability.ParenthesesInCondition, priority: :normal},
        {Credo.Check.Readability.PredicateFunctionNames, priority: :high},
        {Credo.Check.Readability.RedundantBlankLines, priority: :normal},
        {Credo.Check.Readability.TrailingBlankLine, false},
        {Credo.Check.Readability.TrailingWhiteSpace, priority: :high},
        {Credo.Check.Readability.VariableNames, priority: :high},

        {Credo.Check.Refactor.ABCSize, false},
        {Credo.Check.Refactor.CondStatements, priority: :normal},
        # TODO: Check if this is a good metric and tune the max complexity
        {Credo.Check.Refactor.CyclomaticComplexity, priority: :high},
        {Credo.Check.Refactor.FunctionArity, max_arity: 6, ignore_defp: true, priority: :high},
        {Credo.Check.Refactor.MatchInCondition, priority: :normal},
        {Credo.Check.Refactor.NegatedConditionsInUnless, priority: :high},
        {Credo.Check.Refactor.NegatedConditionsWithElse, priority: :high},
        {Credo.Check.Refactor.Nesting, max_nesting: 3, priority: :normal},
        # Is this a duplicate of CyclomaticComplexity ?
        {Credo.Check.Refactor.PerceivedComplexity, false},
        {Credo.Check.Refactor.PipeChainStart, priority: :low},
        {Credo.Check.Refactor.UnlessWithElse, priority: :normal},

        {Credo.Check.Warning.BoolOperationOnSameValues, priority: :normal},
        {Credo.Check.Warning.IExPry, priority: :high},
        {Credo.Check.Warning.IoInspect, priority: :high},
        {Credo.Check.Warning.NameRedeclarationByAssignment, false},
        {Credo.Check.Warning.NameRedeclarationByCase, false},
        {Credo.Check.Warning.NameRedeclarationByDef, false},
        {Credo.Check.Warning.NameRedeclarationByFn, false},
        {Credo.Check.Warning.OperationOnSameValues, priority: :normal},
        {Credo.Check.Warning.OperationWithConstantResult, priority: :normal},
        {Credo.Check.Warning.UnusedEnumOperation, priority: :low},
        {Credo.Check.Warning.UnusedFileOperation, priority: :low},
        {Credo.Check.Warning.UnusedKeywordOperation, priority: :low},
        {Credo.Check.Warning.UnusedListOperation, priority: :low},
        {Credo.Check.Warning.UnusedPathOperation, priority: :low},
        {Credo.Check.Warning.UnusedRegexOperation, priority: :low},
        {Credo.Check.Warning.UnusedStringOperation, priority: :low},
        {Credo.Check.Warning.UnusedTupleOperation, priority: :low},


        # CUSTOM CHECKS
        {Credo.Check.Readability.RefuseTrailingBlankLine, priority: :normal}
      ]
    },
    %{
      name: "ci",
      files: %{
        included: ["apps/*/lib", "app/*/test"]
      },
      check_for_updates: false,
      strict: true,
      requires: ["apps/hell/lib/credo/"],
      checks: [
        {Credo.Check.Consistency.ExceptionNames, priority: :normal},
        {Credo.Check.Consistency.LineEndings, priority: :low},
        {Credo.Check.Consistency.ParameterPatternMatching, priority: :normal},
        {Credo.Check.Consistency.SpaceAroundOperators, priority: :high},
        {Credo.Check.Consistency.SpaceInParentheses, priority: :high},
        {Credo.Check.Consistency.TabsOrSpaces, priority: :high},

        {Credo.Check.Readability.FunctionNames, priority: :high},
        {Credo.Check.Readability.LargeNumbers, priority: :low},
        {Credo.Check.Readability.MaxLineLength, max_length: 80, ignore_definitions: true, ignore_specs: true, priority: :low},
        {Credo.Check.Readability.ModuleAttributeNames, priority: :high},
        {Credo.Check.Readability.ModuleNames, priority: :high},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, priority: :low},
        {Credo.Check.Readability.ParenthesesInCondition, priority: :normal},
        {Credo.Check.Readability.PredicateFunctionNames, priority: :high},
        {Credo.Check.Readability.RedundantBlankLines, priority: :normal},
        {Credo.Check.Readability.TrailingBlankLine, false},
        {Credo.Check.Readability.TrailingWhiteSpace, priority: :high},
        {Credo.Check.Readability.VariableNames, priority: :high},

        {Credo.Check.Refactor.CondStatements, priority: :normal},
        # TODO: Check if this is a good metric and tune the max complexity
        {Credo.Check.Refactor.CyclomaticComplexity, priority: :high},
        {Credo.Check.Refactor.FunctionArity, max_arity: 6, ignore_defp: true, priority: :high},
        {Credo.Check.Refactor.MatchInCondition, priority: :normal},
        {Credo.Check.Refactor.NegatedConditionsInUnless, priority: :high},
        {Credo.Check.Refactor.NegatedConditionsWithElse, priority: :high},
        {Credo.Check.Refactor.Nesting, max_nesting: 3, priority: :normal},
        {Credo.Check.Refactor.UnlessWithElse, priority: :normal},

        {Credo.Check.Warning.BoolOperationOnSameValues, priority: :normal},
        {Credo.Check.Warning.IExPry, priority: :high},
        {Credo.Check.Warning.IoInspect, priority: :high},
        {Credo.Check.Warning.OperationOnSameValues, priority: :normal},
        {Credo.Check.Warning.OperationWithConstantResult, priority: :normal},
        {Credo.Check.Warning.UnusedEnumOperation, priority: :low},
        {Credo.Check.Warning.UnusedFileOperation, priority: :low},
        {Credo.Check.Warning.UnusedKeywordOperation, priority: :low},
        {Credo.Check.Warning.UnusedListOperation, priority: :low},
        {Credo.Check.Warning.UnusedPathOperation, priority: :low},
        {Credo.Check.Warning.UnusedRegexOperation, priority: :low},
        {Credo.Check.Warning.UnusedStringOperation, priority: :low},
        {Credo.Check.Warning.UnusedTupleOperation, priority: :low},


        # CUSTOM CHECKS
        {Credo.Check.Readability.RefuseTrailingBlankLine, priority: :normal}
      ]
    }
  ]
}