classdef (Abstract) htoolChoice < hmockSendRequest
% Tests for backends with ToolChoice support

%   Copyright 2023-2025 The MathWorks, Inc.
    properties(Abstract)
        constructor
        defaultModel
    end

    properties (TestParameter)
        GenericToolChoice = {"auto", "none", "required"}
        AutoOrNone = {"auto", "none"}
    end
    
    methods (Test) % not calling the server
        function errorsWhenPassingToolChoiceWithEmptyTools(testCase)
            testCase.verifyError(@()generate(testCase.defaultModel,"input", ToolChoice="bla"), "llms:mustSetFunctionsForCall");
        end

        function generateToolChoiceMustBeOneOfOverriddenTools(testCase)
            sendRequestMock = testCase.setUpSendRequestMock;

            chatTools = openAIFunction("someFunctionName");
            chat = testCase.constructor("You are a helpful assistant", Tools=chatTools);
            chat.sendRequestFcn = @(varargin) sendRequestMock.sendRequest(varargin{:});

            generateTools = openAIFunction("someOtherFunctionName");
            testCase.verifyError(@() generate(chat,"Hi", "Tools", generateTools, ...
                "ToolChoice", chatTools.FunctionName), ...
                'MATLAB:validators:mustBeMember');
        end

        function generateToolChoiceAutoAndNoneWorkWhenToolsOverriddenToNone(testCase, AutoOrNone)
            sendRequestMock = testCase.setUpSendRequestMock;

            chatTools = openAIFunction("someFunctionName");
            chat = testCase.constructor("You are a helpful assistant", Tools=chatTools);
            chat.sendRequestFcn = @(varargin) sendRequestMock.sendRequest(varargin{:});

            generateTools = openAIFunction.empty;
            response = testCase.verifyWarningFree(@() generate(chat,"Hi", "Tools", generateTools, ...
                "ToolChoice", AutoOrNone));
            calls = testCase.getMockHistory(sendRequestMock);
            testCase.verifySize(calls,[1,1]);
            sentHistory = calls.Inputs{2};
            testCase.verifyFalse(isfield(sentHistory,"tool_choice"));
            testCase.verifyEqual(response,"Hello");
        end

        function generateToolChoiceWorksWithOverriddenTools(testCase, GenericToolChoice)
            import matlab.unittest.constraints.HasField

            sendRequestMock = testCase.setUpSendRequestMock;
            
            chatLevelTools = openAIFunction("funNameAtTopLevel");
            chat = testCase.constructor("You are a helpful assistant", Tools=chatLevelTools);
            chat.sendRequestFcn = @(varargin) sendRequestMock.sendRequest(varargin{:});

            tools = openAIFunction("ToolForGenerate");
            response = testCase.verifyWarningFree(@() generate(chat,"Hi", ...
                Tools=tools, ...
                ToolChoice=GenericToolChoice));

            calls = testCase.getMockHistory(sendRequestMock);

            testCase.verifySize(calls,[1,1]);
            sentHistory = calls.Inputs{2};
            testCase.verifyThat(sentHistory,HasField("tools"));
            expectedTool = struct( ...
                'type', 'function', ...
                'function', struct( ...
                    'name', "ToolForGenerate", ...
                    'parameters', struct( ...
                        'type', "object", ...
                        'properties', struct())));
            testCase.verifySize(sentHistory.tools, [1,1]);
            testCase.verifyEqual(sentHistory.tools{1}, expectedTool);
            testCase.verifyEqual(sentHistory.tool_choice, GenericToolChoice);
            testCase.verifyEqual(response,"Hello");
        end

        function generateToolChoiceWorksWithToolChosenByName(testCase)
            import matlab.unittest.constraints.HasField

            sendRequestMock = testCase.setUpSendRequestMock;
            
            chatLevelTools = openAIFunction("funNameAtTopLevel");
            chat = testCase.constructor("You are a helpful assistant", Tools=chatLevelTools);
            chat.sendRequestFcn = @(varargin) sendRequestMock.sendRequest(varargin{:});

            tools = openAIFunction("ToolForGenerate");
            response = testCase.verifyWarningFree(@() generate(chat,"Hi", ...
                Tools=tools, ...
                ToolChoice="ToolForGenerate"));

            calls = testCase.getMockHistory(sendRequestMock);

            testCase.verifySize(calls,[1,1]);
            sentHistory = calls.Inputs{2};
            testCase.verifyThat(sentHistory,HasField("tools"));
            expectedTool = struct( ...
                'type', 'function', ...
                'function', struct( ...
                    'name', "ToolForGenerate", ...
                    'parameters', struct( ...
                        'type', "object", ...
                        'properties', struct())));
            testCase.verifySize(sentHistory.tools, [1,1]);
            testCase.verifyEqual(sentHistory.tools{1}, expectedTool);
            expectedToolChoice = struct( ...
                'type', "function", ...
                'function', struct( ...
                    'name', "ToolForGenerate"));
            testCase.verifyEqual(sentHistory.tool_choice, expectedToolChoice);
            testCase.verifyEqual(response,"Hello");
        end
    end

    methods (Test) % calling the server, end-to-end tests
        function settingToolChoice(testCase, GenericToolChoice)
            functions = openAIFunction("funName");
            chat = testCase.constructor(Tools=functions);

            testCase.verifyWarningFree(@()generate(chat,"This is okay","ToolChoice", GenericToolChoice));
        end
    end
end
