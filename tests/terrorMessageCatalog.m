classdef terrorMessageCatalog < matlab.unittest.TestCase
% Tests for errorMessageCatalog

%   Copyright 2024 The MathWorks, Inc.

    methods(Test)
        function ensureCorrectCoverage(testCase)
            testCase.verifyClass( ...
                llms.utils.errorMessageCatalog.createCatalog,"dictionary");
        end

        function holeValuesAreUsed(testCase)
            import matlab.unittest.constraints.IsEqualTo

            % we do not check the whole string, because error message
            % text *should* be able to change without test points changing.
            % That is necessary to enable localization.
            messageID = "llms:mustBeValidIndex";

            message1 = llms.utils.errorMessageCatalog.getMessage(messageID, "input1");
            message2 = llms.utils.errorMessageCatalog.getMessage(messageID, "input2");

            testCase.verifyThat(message1, ~IsEqualTo(message2));
            testCase.verifyThat(replace(message1, "input1", "input2"), IsEqualTo(message2));
        end
    end    
end
