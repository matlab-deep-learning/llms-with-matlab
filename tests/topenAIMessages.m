classdef topenAIMessages < matlab.unittest.TestCase
% Tests for openAIMessages

%   Copyright 2023-2024 The MathWorks, Inc.

    properties(TestParameter)
        InvalidInputsUserPrompt = iGetInvalidInputsUserPrompt;
        InvalidInputsUserImagesPrompt = iGetInvalidInputsUserImagesPrompt;
        InvalidInputsFunctionPrompt = iGetInvalidFunctionPrompt;
        InvalidInputsSystemPrompt = iGetInvalidInputsSystemPrompt;
        InvalidInputsResponseMessage = iGetInvalidInputsResponseMessage;
        InvalidRemoveMessage = iGetInvalidRemoveMessage;     
        ValidTextInput = {"This is okay"; 'this is ok'};
    end

    methods(Test)
        function constructorStartsWithEmptyMessages(testCase)
            msgs = openAIMessages;
            testCase.verifyTrue(isempty(msgs.Messages));
        end

        function differentInputTextAccepted(testCase, ValidTextInput)
            msgs = openAIMessages;
            testCase.verifyWarningFree(@()addSystemMessage(msgs, ValidTextInput, ValidTextInput));
            testCase.verifyWarningFree(@()addSystemMessage(msgs, ValidTextInput, ValidTextInput));
            testCase.verifyWarningFree(@()addUserMessage(msgs, ValidTextInput));
            testCase.verifyWarningFree(@()addToolMessage(msgs, ValidTextInput, ValidTextInput, ValidTextInput));
        end
        

        function systemMessageIsAdded(testCase)
            prompt = "Here is a system prompt";
            name = "example";
            msgs = openAIMessages;
            systemPrompt = struct("role", "system", "name", name, "content", prompt);
            msgs = addSystemMessage(msgs, name, prompt);
            testCase.verifyEqual(msgs.Messages{1}, systemPrompt);
        end

        function userMessageIsAdded(testCase)
            prompt = "Here is a user prompt";
            msgs = openAIMessages;
            userPrompt = struct("role", "user", "content", prompt);
            msgs = addUserMessage(msgs, prompt);
            testCase.verifyEqual(msgs.Messages{1}, userPrompt);
        end

        function userImageMessageIsAddedWithLocalImg(testCase)
            prompt = "Here is a user prompt";
            msgs = openAIMessages;
            img = "peppers.png";
            testCase.verifyWarningFree(@()addUserMessageWithImages(msgs, prompt, img));
        end

        function userImageMessageIsAddedWithRemoteImg(testCase)
            prompt = "Here is a user prompt";
            msgs = openAIMessages;
            img = "https://www.mathworks.com/help/examples/matlab/win64/DisplayGrayscaleRGBIndexedOrBinaryImageExample_04.png";
            testCase.verifyWarningFree(@()addUserMessageWithImages(msgs, prompt, img));
        end

        function toolMessageIsAdded(testCase)
            prompt = "20";
            name = "sin";
            id = "123";
            msgs = openAIMessages;
            systemPrompt = struct("tool_call_id", id, "role", "tool", "name", name, "content", prompt);
            msgs = addToolMessage(msgs, id, name, prompt);
            testCase.verifyEqual(msgs.Messages{1}, systemPrompt);
        end

        function assistantMessageIsAdded(testCase)
            prompt = "Here is an assistant prompt";
            msgs = openAIMessages;
            assistantPrompt = struct("role", "assistant", "content", prompt);
            msgs = addResponseMessage(msgs, assistantPrompt);
            testCase.verifyEqual(msgs.Messages{1}, assistantPrompt);
        end

        function assistantToolCallMessageIsAdded(testCase)
            msgs = openAIMessages;
            functionName = "functionName";
            args = "{""arg1"": 1, ""arg2"": 2, ""arg3"": ""3""}";
            funCall = struct("name", functionName, "arguments", args);
            toolCall = struct("id", "123", "type", "function", "function", funCall);
            toolCallPrompt = struct("role", "assistant", "content", "", "tool_calls", []);
            toolCallPrompt.tool_calls = {toolCall};
            msgs = addResponseMessage(msgs, toolCallPrompt);
            testCase.verifyEqual(msgs.Messages{1}, toolCallPrompt);
        end

        function assistantToolCallMessageWithoutArgsIsAdded(testCase)
            msgs = openAIMessages;
            functionName = "functionName";
            funCall = struct("name", functionName, "arguments", "{}");
            toolCall = struct("id", "123", "type", "function", "function", funCall);
            toolCallPrompt = struct("role", "assistant", "content", "","tool_calls", []);
            toolCallPrompt.tool_calls = {toolCall};
            msgs = addResponseMessage(msgs, toolCallPrompt);
            testCase.verifyEqual(msgs.Messages{1}, toolCallPrompt);
        end

        function assistantParallelToolCallMessageIsAdded(testCase)
            msgs = openAIMessages;
            functionName = "functionName";
            args = "{""arg1"": 1, ""arg2"": 2, ""arg3"": ""3""}";
            funCall = struct("name", functionName, "arguments", args);
            toolCall = struct("id", "123", "type", "function", "function", funCall);
            toolCallPrompt = struct("role", "assistant", "content", "", "tool_calls", []);
            toolCallPrompt.tool_calls = [toolCall,toolCall,toolCall];
            msgs = addResponseMessage(msgs, toolCallPrompt);
            testCase.verifyEqual(msgs.Messages{1}, toolCallPrompt);
        end

        function messageGetsRemoved(testCase)
            msgs = openAIMessages;
            idx = 2;
            
            msgs = addSystemMessage(msgs, "name", "content");
            msgs = addUserMessage(msgs, "content"); 
            msgs = addToolMessage(msgs, "123", "name", "content");
            sizeMsgs = length(msgs.Messages);
            % Message exists before removal
            msgToBeRemoved = msgs.Messages{idx};
            testCase.verifyTrue(any(cellfun(@(c) isequal(c,  msgToBeRemoved), msgs.Messages)));
            
            msgs = removeMessage(msgs, idx);
            testCase.verifyFalse(any(cellfun(@(c) isequal(c,  msgToBeRemoved), msgs.Messages)));
            testCase.verifyEqual(length(msgs.Messages), sizeMsgs-1);
        end

        function removalIdxCantBeLargerThanNumElements(testCase)
            msgs = openAIMessages;
            
            msgs = addSystemMessage(msgs, "name", "content");
            msgs = addUserMessage(msgs, "content"); 
            msgs = addToolMessage(msgs, "123", "name", "content");
            sizeMsgs = length(msgs.Messages);

            testCase.verifyError(@()removeMessage(msgs, sizeMsgs+1), "llms:mustBeValidIndex");
        end

        function invalidInputsSystemPrompt(testCase, InvalidInputsSystemPrompt)
            msgs = openAIMessages;
            testCase.verifyError(@()addSystemMessage(msgs,InvalidInputsSystemPrompt.Input{:}), InvalidInputsSystemPrompt.Error);
        end

        function invalidInputsUserPrompt(testCase, InvalidInputsUserPrompt)
            msgs = openAIMessages;
            testCase.verifyError(@()addUserMessage(msgs,InvalidInputsUserPrompt.Input{:}), InvalidInputsUserPrompt.Error);
        end

        function invalidInputsUserImagesPrompt(testCase, InvalidInputsUserImagesPrompt)
            msgs = openAIMessages;
            testCase.verifyError(@()addUserMessageWithImages(msgs,InvalidInputsUserImagesPrompt.Input{:}), InvalidInputsUserImagesPrompt.Error);
        end

        function invalidInputsFunctionPrompt(testCase, InvalidInputsFunctionPrompt)
            msgs = openAIMessages;
            testCase.verifyError(@()addToolMessage(msgs,InvalidInputsFunctionPrompt.Input{:}), InvalidInputsFunctionPrompt.Error);
        end

        function invalidInputsRemove(testCase, InvalidRemoveMessage)
            msgs = openAIMessages;
            testCase.verifyError(@()removeMessage(msgs,InvalidRemoveMessage.Input{:}), InvalidRemoveMessage.Error);
        end

        function invalidInputsResponsePrompt(testCase, InvalidInputsResponseMessage)
            msgs = openAIMessages;
            testCase.verifyError(@()addResponseMessage(msgs,InvalidInputsResponseMessage.Input{:}), InvalidInputsResponseMessage.Error);
        end
    end  
end

function invalidInputsSystemPrompt = iGetInvalidInputsSystemPrompt
    invalidInputsSystemPrompt = struct( ...
        "NonStringInputName", ...
            struct("Input", {{123, "content"}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "NonStringInputContent", ...
            struct("Input", {{"name", 123}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "EmptytName", ...
            struct("Input", {{"", "content"}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "EmptytContent", ...
            struct("Input", {{"name", ""}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "NonScalarInputName", ...
            struct("Input", {{["name1" "name2"], "content"}}, ...
            "Error", "MATLAB:validators:mustBeTextScalar"),...
        ...
        "NonScalarInputContent", ...
            struct("Input", {{"name", ["content1", "content2"]}}, ...
            "Error", "MATLAB:validators:mustBeTextScalar"));
end

function invalidInputsUserPrompt = iGetInvalidInputsUserPrompt
    invalidInputsUserPrompt = struct( ...
        "NonStringInput", ...
            struct("Input", {{123}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "NonScalarInput", ...
            struct("Input", {{["prompt1" "prompt2"]}}, ...
            "Error", "MATLAB:validators:mustBeTextScalar"), ...
            ...
        "EmptyInput", ...
            struct("Input", {{""}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"));
end

function invalidInputsUserImagesPrompt = iGetInvalidInputsUserImagesPrompt
    invalidInputsUserImagesPrompt = struct( ...
        "NonStringInput", ...
            struct("Input", {{123, "peppers.png"}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "NonScalarInput", ...
            struct("Input", {{["prompt1" "prompt2"], "peppers.png"}}, ...
            "Error", "MATLAB:validators:mustBeTextScalar"), ...
            ...
        "EmptyInput", ...
            struct("Input", {{"", "peppers.png"}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "NonTextImage", ...
            struct("Input", {{"prompt", 123}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"),...
        ...
        "EmptyImageName", ...
            struct("Input", {{"prompt", 123}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"),...
        ...
        "InvalidDetail", ...
            struct("Input", {{"prompt", "peppers.png", "Detail", "invalid"}}, ...
            "Error", "MATLAB:validators:mustBeMember"));
end

function invalidFunctionPrompt = iGetInvalidFunctionPrompt
    invalidFunctionPrompt = struct( ...
        "NonStringInputName", ...
            struct("Input", {{"123", 123, "content"}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "NonStringInputContent", ...
            struct("Input", {{"123", "name", 123}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "EmptytName", ...
            struct("Input", {{"123", "", "content"}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "EmptytContent", ...
            struct("Input", {{"123", "name", ""}}, ...
            "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
        ...
        "NonScalarInputName", ...
            struct("Input", {{"123", ["name1" "name2"], "content"}}, ...
            "Error", "MATLAB:validators:mustBeTextScalar"),...
        ...
        "NonScalarInputContent", ...
            struct("Input", {{"123","name", ["content1", "content2"]}}, ...
            "Error", "MATLAB:validators:mustBeTextScalar"));
end

function invalidRemoveMessage = iGetInvalidRemoveMessage
    invalidRemoveMessage = struct( ...
        "NonInteger", ...
            struct("Input", {{0.5}}, ...
            "Error", "MATLAB:validators:mustBeInteger"), ...
        ...
        "NonPositive", ...
            struct("Input", {{0}}, ...
            "Error", "MATLAB:validators:mustBePositive"), ...
        ...
        "NonScalarInput", ...
            struct("Input", {{[1 2]}}, ...
            "Error", "MATLAB:validation:IncompatibleSize"));
end

function invalidInputsResponseMessage = iGetInvalidInputsResponseMessage
    invalidInputsResponseMessage = struct( ...
        "NonStructInput", ... 
            struct("Input", {{123}},...
            "Error", "MATLAB:validation:UnableToConvert"),...
        ...
        "NonExistentRole", ... 
            struct("Input", {{struct("role", "123", "content", "123")}},...
            "Error", "llms:mustBeAssistantCall"),...
        ...
        "NonExistentContent", ... 
            struct("Input", {{struct("role", "assistant")}},...
            "Error", "llms:mustBeAssistantCall"),...
        ...
        "EmptyContent", ... 
            struct("Input", {{struct("role", "assistant", "content", "")}},...
            "Error", "llms:mustBeAssistantWithContent"),...
        ...
        "NonScalarContent", ... 
            struct("Input", {{struct("role", "assistant", "content", ["a", "b"])}},...
            "Error", "llms:mustBeAssistantWithContent"));
end