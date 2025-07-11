classdef (Abstract) hopenAIChat < hstructuredOutput & htoolCalls
% Tests for OpenAI-based chats (openAIChat, azureChat)

%   Copyright 2023-2025 The MathWorks, Inc.

    properties(Abstract,TestParameter)
        ValidConstructorInput
        InvalidConstructorInput
        InvalidGenerateInput
        InvalidValuesSetters
    end
    properties(TestParameter)
        StringInputs = struct('string',{"hi"},'char',{'hi'},'cellstr',{{'hi'}});
    end

    properties(Abstract)
        constructor
        defaultModel
        visionModel
        gpt35Model
    end
    
    methods(Test)
        % Test methods
        function generateAcceptsSingleStringAsInput(testCase,StringInputs)
            response = testCase.verifyWarningFree(...
                @()generate(testCase.defaultModel,StringInputs));
            testCase.verifyClass(response,'string');
            testCase.verifyGreaterThan(strlength(response),0);
        end

        function generateMultipleResponses(testCase)
            [~,~,response] = generate(testCase.defaultModel,"What is a cat?",NumCompletions=3);
            testCase.verifySize(response.Body.Data.choices,[3,1]);
        end

        function generateAcceptsMessagesAsInput(testCase)
            messages = messageHistory;
            messages = addUserMessage(messages, "This should be okay.");

            testCase.verifyWarningFree(...
                @()generate(testCase.defaultModel,messages));
        end

        function validConstructorCalls(testCase,ValidConstructorInput)
            if isempty(ValidConstructorInput.ExpectedWarning)
                chat = testCase.verifyWarningFree(...
                    @() testCase.constructor(ValidConstructorInput.Input{:}));
            else
                chat = testCase.verifyWarning(...
                    @() testCase.constructor(ValidConstructorInput.Input{:}), ...
                    ValidConstructorInput.ExpectedWarning);
            end
            properties = ValidConstructorInput.VerifyProperties;
            for prop=string(fieldnames(properties)).'
                testCase.verifyEqual(chat.(prop),properties.(prop),"Property " + prop);
            end
        end

        function fixedSeedFixesResult(testCase)
            % Seed is "beta" in OpenAI documentation
            % and not reliable at this time.
            testCase.assumeFail("disabled since the server is unreliable in honoring the Seed parameter");

            result1 = generate(testCase.defaultModel,"This is okay", "Seed", 2);
            result2 = generate(testCase.defaultModel,"This is okay", "Seed", 2);
            testCase.verifyEqual(result1,result2);
        end

        function invalidInputsConstructor(testCase, InvalidConstructorInput)
            testCase.verifyError(@()testCase.constructor(InvalidConstructorInput.Input{:}), InvalidConstructorInput.Error);
        end

        function generateWithStreamFunAndMaxNumTokens(testCase)
            sf = @(x) x;
            chat = testCase.constructor(StreamFun=sf);
            result = generate(chat,"Why is a raven like a writing desk?",MaxNumTokens=5);
            testCase.verifyClass(result,"string");
            testCase.verifyLessThan(strlength(result), 100);
        end

        function generateWithImage(testCase)
            image_path = "peppers.png";
            emptyMessages = messageHistory;
            messages = addUserMessageWithImages(emptyMessages,"What is in the image?",image_path);

            text = generate(testCase.visionModel,messages);
            testCase.verifyThat(text,matlab.unittest.constraints.ContainsSubstring("pepper"));
        end

        function generateWithMultipleImages(testCase)
            import matlab.unittest.constraints.ContainsSubstring
            image_path = "peppers.png";
            emptyMessages = messageHistory;
            messages = addUserMessageWithImages(emptyMessages,"Compare these images.",[image_path,image_path]);

            text = generate(testCase.visionModel,messages);
            testCase.verifyThat(text, ...
                ContainsSubstring("same") | ...
                ContainsSubstring("identical") | ...
                ContainsSubstring("very similar"));
        end

        function generateOverridesProperties(testCase)
            import matlab.unittest.constraints.EndsWithSubstring
            text = generate(testCase.defaultModel, "Please count from 1 to 10.", Temperature = 0, StopSequences = "4");
            testCase.verifyThat(text, EndsWithSubstring("3, "));
        end

        function invalidInputsGenerate(testCase, InvalidGenerateInput)
            f = openAIFunction("validfunction");
            chat = testCase.constructor(Tools=f, APIKey="this-is-not-a-real-key");

            testCase.verifyError(@()generate(chat,InvalidGenerateInput.Input{:}), InvalidGenerateInput.Error);
        end

        function invalidSetters(testCase, InvalidValuesSetters)
            chat = testCase.constructor();
            function assignValueToProperty(property, value)
                chat.(property) = value;
            end
            
            testCase.verifyError(@()assignValueToProperty(InvalidValuesSetters.Property,InvalidValuesSetters.Value), InvalidValuesSetters.Error);
        end

        function doReturnErrors(testCase)
            % This input is considerably longer than accepted as input for
            % GPT-3.5 (16385 tokens)
            wayTooLong = string(repmat('a ',1,20000));
            testCase.verifyError(@() generate(testCase.gpt35Model,wayTooLong), "llms:apiReturnedError");
        end

        function createChatWithStreamFunc(testCase)
            function seen = sf(str)
                persistent data;
                if isempty(data)
                    data = strings(1, 0);
                end
                % Append streamed text to an empty string array of length 1
                data = [data, str];
                seen = data;
            end
            chat = testCase.constructor(StreamFun=@sf);

            testCase.verifyWarningFree(@()generate(chat, "Hello world."));
            % Checking that persistent data, which is still stored in
            % memory, is greater than 1. This would mean that the stream
            % function has been called and streamed some text.
            testCase.verifyGreaterThan(numel(sf("")), 1);
        end

        function errorJSONResponseFormat(testCase)
            testCase.verifyError( ...
                @() generate(testCase.structuredModel,"create some address",ResponseFormat="json"), ...
                "llms:warningJsonInstruction");
        end

        function jsonFormatWithPrompt(testCase)
            testCase.verifyClass( ...
                generate(testCase.structuredModel,"create some address, return json",ResponseFormat="json"), ...
                "string");
        end

        function keyNotFound(testCase)
            % to verify the error, we need to unset the environment variable
            % OPENAI_API_KEY, if given. Use a fixture to restore the
            % value on leaving the test point:
            import matlab.unittest.fixtures.EnvironmentVariableFixture
            testCase.applyFixture(EnvironmentVariableFixture("OPENAI_API_KEY","dummy"));
            unsetenv("OPENAI_API_KEY");
            testCase.applyFixture(EnvironmentVariableFixture("AZURE_OPENAI_API_KEY","dummy"));
            unsetenv("AZURE_OPENAI_API_KEY");
            testCase.verifyError(testCase.constructor, "llms:keyMustBeSpecified");
        end
    end
end
