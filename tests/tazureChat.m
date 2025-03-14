classdef tazureChat < hopenAIChat
% Tests for azureChat

%   Copyright 2024-2025 The MathWorks, Inc.

    properties(TestParameter)
        ValidConstructorInput = iGetValidConstructorInput();
        InvalidConstructorInput = iGetInvalidConstructorInput;
        InvalidGenerateInput = iGetInvalidGenerateInput;
        InvalidValuesSetters = iGetInvalidValuesSetters;
        APIVersions = iGetAPIVersions();
    end

    properties
        constructor = @azureChat;
        defaultModel = azureChat;
        visionModel = azureChat(Deployment="gpt-4o");
        structuredModel = azureChat("Deployment","gpt-4o-2024-08-06");
    end

    methods(Test)
        function constructChatWithAllNVP(testCase)
            deploymentID = "hello";
            functions = openAIFunction("funName");
            temperature = 0;
            topP = 1;
            stop = ["[END]", "."];
            apiKey = "this-is-not-a-real-key";
            presenceP = -2;
            frequenceP = 2;
            systemPrompt = "This is a system prompt";
            timeout = 3;
            chat = azureChat(systemPrompt, DeploymentID=deploymentID, Tools=functions, ...
                Temperature=temperature, TopP=topP, StopSequences=stop, APIKey=apiKey,...
                FrequencyPenalty=frequenceP, PresencePenalty=presenceP, TimeOut=timeout);
            testCase.verifyEqual(chat.Temperature, temperature);
            testCase.verifyEqual(chat.TopP, topP);
            testCase.verifyEqual(chat.StopSequences, stop);
            testCase.verifyEqual(chat.FrequencyPenalty, frequenceP);
            testCase.verifyEqual(chat.PresencePenalty, presenceP);
        end

        function doGenerateUsingSystemPrompt(testCase)
            testCase.assumeTrue(isenv("AZURE_OPENAI_API_KEY"),"end-to-end test requires environment variables AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT.");
            chat = azureChat("You are a helpful assistant");
            response = testCase.verifyWarningFree(@() generate(chat,"Hi"));
            testCase.verifyClass(response,'string');
            testCase.verifyGreaterThan(strlength(response),0);
        end

        function generateMultipleResponses(testCase)
            chat = azureChat;
            [~,~,response] = generate(chat,"What is a cat?",NumCompletions=3);
            testCase.verifySize(response.Body.Data.choices,[3,1]);
        end

        function jsonFormatWithSystemPrompt(testCase)
            chat = azureChat("Respond in JSON format.","Deployment","gpt-4o-2024-08-06");
            testCase.verifyClass( ...
                generate(chat,"create some address",ResponseFormat='json'), ...
                "string");
        end

        function responseFormatRequiresNewAPI(testCase)
            chat = azureChat(APIVersion="2024-02-01");
            testCase.verifyError(@() generate(chat, ...
                "What is the smallest prime?", ...
                ResponseFormat=struct("number",1)), ...
                "llms:structuredOutputRequiresAPI");
        end

        function maxNumTokensWithReasoningModel(testCase)
            % Unlike OpenAI, Azure requires different parameter names for
            % different models (max_tokens vs max_completion_tokens). Since
            % we do not even know what model some deployment uses (us naming
            % them after the model deployed is not a guarantee), that is a
            % somewhat painful distinction.
            testCase.verifyWarningFree(@() generate( ...
                azureChat(DeploymentID="gpt-35-turbo-16k-0613"), ...
                "What is object oriented design?", MaxNumTokens=23));
            testCase.verifyWarningFree(@() generate( ...
                azureChat(DeploymentID="o1-mini"), ...
                "What is object oriented design?", MaxNumTokens=23));
        end

        function generateWithImage(testCase)
            chat = azureChat(DeploymentID="gpt-4o");
            image_path = "peppers.png";
            emptyMessages = messageHistory;
            messages = addUserMessageWithImages(emptyMessages,"What is in the image?",image_path);

            text = generate(chat,messages);
            testCase.verifyThat(text,matlab.unittest.constraints.ContainsSubstring("pepper"));
        end

        function generateWithMultipleImages(testCase)
            import matlab.unittest.constraints.ContainsSubstring
            chat = azureChat(DeploymentID="gpt-4o");
            image_path = "peppers.png";
            emptyMessages = messageHistory;
            messages = addUserMessageWithImages(emptyMessages,"Compare these images.",[image_path,image_path]);

            text = generate(chat,messages);
            testCase.verifyThat(text,ContainsSubstring("same") | ContainsSubstring("identical"));
        end

        function generateOverridesProperties(testCase)
            import matlab.unittest.constraints.EndsWithSubstring
            chat = azureChat;
            text = generate(chat, "Please count from 1 to 10.", Temperature = 0, StopSequences = "4");
            testCase.verifyThat(text, EndsWithSubstring("3, "));
        end

        function shortErrorForBadEndpoint(testCase)
            chat = azureChat(Endpoint="https://nobodyhere.whatever/");
            caught = false;
            try
                generate(chat,"input");
            catch ME
                caught = ME;
            end
            testCase.assertClass(caught,"MException");
            testCase.verifyEqual(caught.identifier,'MATLAB:webservices:UnknownHost');
            testCase.verifyEmpty(caught.cause);
        end

        function canUseAPIVersions(testCase, APIVersions)
            % Test that we can use different APIVersion value to call 
            % azureChat.generate

            testCase.assumeTrue(isenv("AZURE_OPENAI_API_KEY"),"end-to-end test requires environment variables AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, and AZURE_OPENAI_DEPLOYMENT.");
            chat = azureChat("APIVersion", APIVersions);

            response = testCase.verifyWarningFree(@() generate(chat,"How similar is the DNA of a cat and a tiger?"));
            testCase.verifyClass(response,'string');
            testCase.verifyGreaterThan(strlength(response),0);
        end

        function specialErrorForUnsupportedResponseFormat(testCase)
            % Our "gpt-4o" deployment has the model version 2024-05-13,
            % which does not support structured output
            testCase.verifyError(@() generate(...
                azureChat(DeploymentID="gpt-4o"), ...
                "What is the smallest prime?", ...
                ResponseFormat=struct("number",1)), ...
                "llms:noStructuredOutputForAzureDeployment");
        end

        function endpointNotFound(testCase)
            % to verify the error, we need to unset the environment variable
            % AZURE_OPENAI_ENDPOINT, if given. Use a fixture to restore the
            % value on leaving the test point
            import matlab.unittest.fixtures.EnvironmentVariableFixture
            testCase.applyFixture(EnvironmentVariableFixture("AZURE_OPENAI_ENDPOINT","dummy"));
            unsetenv("AZURE_OPENAI_ENDPOINT");
            testCase.verifyError(@()azureChat, "llms:endpointMustBeSpecified");
        end

        function deploymentNotFound(testCase)
            % to verify the error, we need to unset the environment variable
            % AZURE_OPENAI_DEPLOYMENT, if given. Use a fixture to restore the
            % value on leaving the test point
            import matlab.unittest.fixtures.EnvironmentVariableFixture
            testCase.applyFixture(EnvironmentVariableFixture("AZURE_OPENAI_DEPLOYMENT","dummy"));
            unsetenv("AZURE_OPENAI_DEPLOYMENT");
            testCase.verifyError(@()azureChat, "llms:deploymentMustBeSpecified");
        end

    end
end

function validConstructorInput = iGetValidConstructorInput()
validConstructorInput = struct( ...
    "Empty", struct( ...
        "Input",{{}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1}, ...
                "TopP", {1}, ...
                "StopSequences", {string([])}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {10}, ...
                "FunctionNames", {[]}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"text"} ...
            ) ...
        ),...
    "SomeSettings", struct( ...
        "Input",{{"Temperature",1.23,"TopP",0.6,"TimeOut",120,"ResponseFormat","json"}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1.23}, ...
                "TopP", {0.6}, ...
                "StopSequences", {string([])}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {120}, ...
                "FunctionNames", {[]}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"json"} ...
            ) ...
        ));
end

function invalidValuesSetters = iGetInvalidValuesSetters

invalidValuesSetters = struct( ...
    "InvalidTemperatureType", struct( ...
        "Property", "Temperature", ...
        "Value", "2", ...
        "Error", "MATLAB:invalidType"), ...
    ...
    "InvalidTemperatureSize", struct( ...
        "Property", "Temperature", ...
        "Value", [1 1 1], ...
        "Error", "MATLAB:expectedScalar"), ...
    ...
    "TemperatureTooLarge", struct( ...
        "Property", "Temperature", ...
        "Value", 20, ...
        "Error", "MATLAB:notLessEqual"), ...
    ...
    "TemperatureTooSmall", struct( ...
        "Property", "Temperature", ...
        "Value", -20, ...
        "Error", "MATLAB:expectedNonnegative"), ...
    ...
    "InvalidTopPType", struct( ...
        "Property", "TopP", ...
        "Value", "2", ...
        "Error", "MATLAB:invalidType"), ...
    ...
    "InvalidTopPSize", struct( ...
        "Property", "TopP", ...
        "Value", [1 1 1], ...
        "Error", "MATLAB:expectedScalar"), ...
    ...
    "TopPTooLarge", struct( ...
        "Property", "TopP", ...
        "Value", 20, ...
        "Error", "MATLAB:notLessEqual"), ...
    ...
    "TopPTooSmall", struct( ...
        "Property", "TopP", ...
        "Value", -20, ...
        "Error", "MATLAB:expectedNonnegative"), ...
    ...
    "WrongTypeStopSequences", struct( ...
        "Property", "StopSequences", ...
        "Value", 123, ...
        "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
    ...
    "WrongSizeStopNonVector", struct( ...
        "Property", "StopSequences", ...
        "Value", repmat("stop", 4), ...
        "Error", "MATLAB:validators:mustBeVector"), ...
    ...
    "EmptyStopSequences", struct( ...
        "Property", "StopSequences", ...
        "Value", "", ...
        "Error", "MATLAB:validators:mustBeNonzeroLengthText"), ...
    ...
    "WrongSizeStopSequences", struct( ...
        "Property", "StopSequences", ...
        "Value", ["1" "2" "3" "4" "5"], ...
        "Error", "llms:stopSequencesMustHaveMax4Elements"), ...
    ...
    "InvalidPresencePenalty", struct( ...
        "Property", "PresencePenalty", ...
        "Value", "2", ...
        "Error", "MATLAB:invalidType"), ...
    ...
    "InvalidPresencePenaltySize", struct( ...
        "Property", "PresencePenalty", ...
        "Value", [1 1 1], ...
        "Error", "MATLAB:expectedScalar"), ...
    ...
    "PresencePenaltyTooLarge", struct( ...
        "Property", "PresencePenalty", ...
        "Value", 20, ...
        "Error", "MATLAB:notLessEqual"), ...
    ...
    "PresencePenaltyTooSmall", struct( ...
        "Property", "PresencePenalty", ...
        "Value", -20, ...
        "Error", "MATLAB:notGreaterEqual"), ...
    ...
    "InvalidFrequencyPenalty", struct( ...
        "Property", "FrequencyPenalty", ...
        "Value", "2", ...
        "Error", "MATLAB:invalidType"), ...
    ...
    "InvalidFrequencyPenaltySize", struct( ...
        "Property", "FrequencyPenalty", ...
        "Value", [1 1 1], ...
        "Error", "MATLAB:expectedScalar"), ...
    ...
    "FrequencyPenaltyTooLarge", struct( ...
        "Property", "FrequencyPenalty", ...
        "Value", 20, ...
        "Error", "MATLAB:notLessEqual"), ...
    ...
    "FrequencyPenaltyTooSmall", struct( ...
        "Property", "FrequencyPenalty", ...
        "Value", -20, ...
        "Error", "MATLAB:notGreaterEqual"));
end

function invalidConstructorInput = iGetInvalidConstructorInput
validFunction = openAIFunction("funName");
invalidConstructorInput = struct( ...
    "InvalidResponseFormatValue", struct( ...
        "Input",{{"ResponseFormat", "foo" }},...
        "Error", "llms:incorrectResponseFormat"), ...
    ...
    "InvalidResponseFormatType", struct( ...
        "Input",{{"ResponseFormat", 1}},...
        "Error", "llms:incorrectResponseFormat"), ...
    ...
    "InvalidResponseFormatSize", struct( ...
        "Input",{{"ResponseFormat", ["text" "text"] }},...
        "Error", "MATLAB:validators:mustBeTextScalar"), ...
    ...
    "InvalidStreamFunType", struct( ...
        "Input",{{"StreamFun", "2" }},...
        "Error", "MATLAB:validators:mustBeA"), ...
    ...
    "InvalidStreamFunSize", struct( ...
        "Input",{{"StreamFun", [1 1 1] }},...
        "Error", "MATLAB:validation:IncompatibleSize"), ...
    ...
    "InvalidTimeOutType", struct( ...
        "Input",{{"TimeOut", "2" }},...
        "Error", "MATLAB:validators:mustBeNumeric"), ...
    ...
    "InvalidTimeOutSize", struct( ...
        "Input",{{"TimeOut", [1 1 1] }},...
        "Error", "MATLAB:validation:IncompatibleSize"), ...
    ...
    "WrongTypeSystemPrompt",struct( ...
        "Input",{{ 123 }},...
        "Error","MATLAB:validators:mustBeTextScalar"),...
    ...
    "WrongSizeSystemPrompt",struct( ...
        "Input",{{ ["test"; "test"] }},...
        "Error","MATLAB:validators:mustBeTextScalar"),...
    ...
    "InvalidToolsType",struct( ...
        "Input",{{"Tools", "a" }},...
        "Error","MATLAB:validators:mustBeA"),...
    ...
    "InvalidToolsSize",struct( ...
        "Input",{{"Tools", repmat(validFunction, 2, 2) }},...
        "Error","MATLAB:validation:IncompatibleSize"),...
    ...
    "InvalidAPIVersionType",struct( ...
        "Input",{{"APIVersion", 0}},...
        "Error","MATLAB:validators:mustBeMember"),...
    ...
    "InvalidAPIVersionSize",struct( ...
        "Input",{{"APIVersion", ["2023-05-15", "2023-05-15"]}},...
        "Error","MATLAB:validation:IncompatibleSize"),...
    ...
    "InvalidAPIVersionOption",struct( ...
        "Input",{{ "APIVersion", "gpt" }},...
        "Error","MATLAB:validators:mustBeMember"),...
    ...
    "InvalidTemperatureType",struct( ...
        "Input",{{ "Temperature" "2" }},...
        "Error","MATLAB:invalidType"),...
    ...
    "InvalidTemperatureSize",struct( ...
        "Input",{{ "Temperature" [1 1 1] }},...
        "Error","MATLAB:expectedScalar"),...
    ...
    "TemperatureTooLarge",struct( ...
        "Input",{{ "Temperature" 20 }},...
        "Error","MATLAB:notLessEqual"),...
    ...
    "TemperatureTooSmall",struct( ...
        "Input",{{ "Temperature" -20 }},...
        "Error","MATLAB:expectedNonnegative"),...
    ...
    "InvalidTopPType",struct( ...
        "Input",{{  "TopP" "2" }},...
        "Error","MATLAB:invalidType"),...
    ...
    "InvalidTopPSize",struct( ...
        "Input",{{  "TopP" [1 1 1] }},...
        "Error","MATLAB:expectedScalar"),...
    ...
    "TopPTooLarge",struct( ...
        "Input",{{  "TopP" 20 }},...
        "Error","MATLAB:notLessEqual"),...
    ...
    "TopPTooSmall",struct( ...
        "Input",{{ "TopP" -20 }},...
        "Error","MATLAB:expectedNonnegative"),...
    ...
    "WrongTypeStopSequences",struct( ...
        "Input",{{ "StopSequences" 123}},...
        "Error","MATLAB:validators:mustBeNonzeroLengthText"),...
    ...
    "WrongSizeStopNonVector",struct( ...
        "Input",{{ "StopSequences" repmat("stop", 4) }},...
        "Error","MATLAB:validators:mustBeVector"),...
    ...
    "EmptyStopSequences",struct( ...
        "Input",{{ "StopSequences" ""}},...
        "Error","MATLAB:validators:mustBeNonzeroLengthText"),...
    ...
    "WrongSizeStopSequences",struct( ...
        "Input",{{ "StopSequences" ["1" "2" "3" "4" "5"]}},...
        "Error","llms:stopSequencesMustHaveMax4Elements"),...
    ...
    "InvalidPresencePenalty",struct( ...
        "Input",{{ "PresencePenalty" "2" }},...
        "Error","MATLAB:invalidType"),...
    ...
    "InvalidPresencePenaltySize",struct( ...
        "Input",{{ "PresencePenalty" [1 1 1] }},...
        "Error","MATLAB:expectedScalar"),...
    ...
    "PresencePenaltyTooLarge",struct( ...
        "Input",{{ "PresencePenalty" 20 }},...
        "Error","MATLAB:notLessEqual"),...
    ...
    "PresencePenaltyTooSmall",struct( ...
        "Input",{{ "PresencePenalty" -20 }},...
        "Error","MATLAB:notGreaterEqual"),...
    ...
    "InvalidFrequencyPenalty",struct( ...
        "Input",{{ "FrequencyPenalty" "2" }},...
        "Error","MATLAB:invalidType"),...
    ...
    "InvalidFrequencyPenaltySize",struct( ...
        "Input",{{ "FrequencyPenalty" [1 1 1] }},...
        "Error","MATLAB:expectedScalar"),...
    ...
    "FrequencyPenaltyTooLarge",struct( ...
        "Input",{{ "FrequencyPenalty" 20 }},...
        "Error","MATLAB:notLessEqual"),...
    ...
    "FrequencyPenaltyTooSmall",struct( ...
        "Input",{{ "FrequencyPenalty" -20 }},...
        "Error","MATLAB:notGreaterEqual"),...
    ...
    "InvalidApiKeyType",struct( ...
        "Input",{{ "APIKey" 123 }},...
        "Error","MATLAB:validators:mustBeNonzeroLengthText"),...
    ...
    "InvalidApiKeySize",struct( ...
        "Input",{{ "APIKey" ["abc" "abc"] }},...
        "Error","MATLAB:validators:mustBeTextScalar"));
end

function invalidGenerateInput = iGetInvalidGenerateInput
emptyMessages = messageHistory;
validMessages = addUserMessage(emptyMessages,"Who invented the telephone?");

invalidGenerateInput = struct( ...
        "EmptyInput",struct( ...
            "Input",{{ [] }},...
            "Error","llms:mustBeMessagesOrTxt"),...
        ...
        "InvalidInputType",struct( ...
            "Input",{{ 123 }},...
            "Error","llms:mustBeMessagesOrTxt"),...
        ...
        "EmptyMessages",struct( ...
            "Input",{{ emptyMessages }},...
            "Error","llms:mustHaveMessages"),...
        ...
        "InvalidMaxNumTokensType",struct( ...
            "Input",{{ validMessages  "MaxNumTokens" "2" }},...
            "Error","MATLAB:validators:mustBeNumeric"),...
        ...
        "InvalidMaxNumTokensValue",struct( ...
            "Input",{{ validMessages  "MaxNumTokens" 0 }},...
            "Error","MATLAB:validators:mustBePositive"),...
        ...
        "InvalidNumCompletionsType",struct( ...
            "Input",{{ validMessages  "NumCompletions" "2" }},...
            "Error","MATLAB:validators:mustBeNumeric"),...
        ...
        "InvalidNumCompletionsValue",struct( ...
            "Input",{{ validMessages  "NumCompletions" 0 }},...
            "Error","MATLAB:validators:mustBePositive"), ...
        ...
        "InvalidToolChoiceValue",struct( ...
            "Input",{{ validMessages  "ToolChoice" "functionDoesNotExist" }},...
            "Error","MATLAB:validators:mustBeMember"),...
        ...
        "InvalidToolChoiceType",struct( ...
            "Input",{{ validMessages  "ToolChoice" 0 }},...
            "Error","MATLAB:validators:mustBeTextScalar"),...
        ...
        "InvalidToolChoiceSize",struct( ...
            "Input",{{ validMessages  "ToolChoice" ["validfunction", "validfunction"] }},...
            "Error","MATLAB:validators:mustBeTextScalar"));
end

function apiVersions = iGetAPIVersions()
apiVersions = cellstr(llms.azure.apiVersions);
end
