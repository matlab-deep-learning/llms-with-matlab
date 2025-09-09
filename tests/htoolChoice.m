classdef (Abstract) htoolChoice < matlab.mock.TestCase
% Tests for backends with ToolChoice support

%   Copyright 2023-2025 The MathWorks, Inc.
    properties(Abstract)
        constructor
        defaultModel
    end
    
    methods (Test) % not calling the server
        function errorsWhenPassingToolChoiceWithEmptyTools(testCase)
            testCase.verifyError(@()generate(testCase.defaultModel,"input", ToolChoice="bla"), "llms:mustSetFunctionsForCall");
        end
    end

    methods (Test) % calling the server, end-to-end tests
        function settingToolChoiceWithNone(testCase)
            functions = openAIFunction("funName");
            chat = testCase.constructor(Tools=functions);

            testCase.verifyWarningFree(@()generate(chat,"This is okay","ToolChoice","none"));
        end

        function settingToolChoiceAsRequired(testCase)
            functions = openAIFunction("funName");
            chat = testCase.constructor(Tools=functions);

            testCase.verifyWarningFree(@()generate(chat,"This is okay","ToolChoice","required"));
        end
    end
end
