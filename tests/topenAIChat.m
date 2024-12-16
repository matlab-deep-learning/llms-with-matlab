classdef topenAIChat < hopenAIChat
% Tests for openAIChat

%   Copyright 2023-2024 The MathWorks, Inc.

    properties(TestParameter)
        ValidConstructorInput = iGetValidConstructorInput();
        InvalidConstructorInput = iGetInvalidConstructorInput();
        InvalidGenerateInput = iGetInvalidGenerateInput();
        InvalidValuesSetters = iGetInvalidValuesSetters();
        ModelName = cellstr(llms.openai.models);
    end

    properties
        constructor = @openAIChat;
        defaultModel = openAIChat;
        visionModel = openAIChat;
        structuredModel = openAIChat;
        noStructuredOutputModel = openAIChat(ModelName="gpt-3.5-turbo");
    end
    
    methods(Test)
        % Test methods
        function constructChatWithAllNVP(testCase)
            functions = openAIFunction("funName");
            modelName = "gpt-4o-mini";
            temperature = 0;
            topP = 1;
            stop = ["[END]", "."];
            apiKey = "this-is-not-a-real-key";
            presenceP = -2;
            frequenceP = 2;
            systemPrompt = "This is a system prompt";
            timeout = 3;
            chat = openAIChat(systemPrompt, Tools=functions, ModelName=modelName, ...
                Temperature=temperature, TopP=topP, StopSequences=stop, APIKey=apiKey,...
                FrequencyPenalty=frequenceP, PresencePenalty=presenceP, TimeOut=timeout);

            testCase.verifyEqual(chat.ModelName, modelName);
            testCase.verifyEqual(chat.Temperature, temperature);
            testCase.verifyEqual(chat.TopP, topP);
            testCase.verifyEqual(chat.StopSequences, stop);
            testCase.verifyEqual(chat.FrequencyPenalty, frequenceP);
            testCase.verifyEqual(chat.PresencePenalty, presenceP);
        end

        function canUseModel(testCase,ModelName)
            testCase.verifyClass(generate(...
                    openAIChat(ModelName=ModelName), ...
                    "hi",MaxNumTokens=1), ...
                "string");
        end

        function gpt35TurboErrorsForImages(testCase)
            chat = openAIChat(APIKey="this-is-not-a-real-key",ModelName="gpt-3.5-turbo");
            image_path = "peppers.png";
            emptyMessages = messageHistory;
            inValidMessages = addUserMessageWithImages(emptyMessages,"What is in the image?",image_path);

            testCase.verifyError(@()generate(chat,inValidMessages), "llms:invalidContentTypeForModel")
        end

        function jsonFormatWithSystemPrompt(testCase)
            chat = openAIChat("Respond in JSON format.");
            testCase.verifyClass( ...
                generate(chat,"create some address",ResponseFormat="json"), ...
                "string");
        end

        function doReturnErrors(testCase)
            chat = openAIChat(ModelName="gpt-3.5-turbo");
            % This input is considerably longer than accepted as input for
            % GPT-3.5 (16385 tokens)
            wayTooLong = string(repmat('a ',1,20000));
            testCase.verifyError(@() generate(chat,wayTooLong), "llms:apiReturnedError");
        end

        function specialErrorForUnsupportedResponseFormat(testCase)
            testCase.verifyError(@() generate(testCase.noStructuredOutputModel, ...
                "What is the smallest prime?", ...
                ResponseFormat=struct("number",1)), ...
                "llms:noStructuredOutputForModel");
        end


    end
end

function invalidValuesSetters = iGetInvalidValuesSetters()

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

function validConstructorInput = iGetValidConstructorInput()
% while it is valid to provide the key via an environment variable,
% this test set does not use that, for easier setup
validConstructorInput = struct( ...
    "JustKey", struct( ...
        "Input",{{"APIKey","this-is-not-a-real-key"}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1}, ...
                "TopP", {1}, ...
                "StopSequences", {string([])}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {10}, ...
                "FunctionNames", {[]}, ...
                "ModelName", {"gpt-4o-mini"}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"text"} ...
            ) ...
        ), ...
    "SystemPrompt", struct( ...
        "Input",{{"system prompt","APIKey","this-is-not-a-real-key"}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1}, ...
                "TopP", {1}, ...
                "StopSequences", {string([])}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {10}, ...
                "FunctionNames", {[]}, ...
                "ModelName", {"gpt-4o-mini"}, ...
                "SystemPrompt", {{struct("role","system","content","system prompt")}}, ...
                "ResponseFormat", {"text"} ...
            ) ...
        ), ...
    "Temperature", struct( ...
        "Input",{{"APIKey","this-is-not-a-real-key","Temperature",2}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {2}, ...
                "TopP", {1}, ...
                "StopSequences", {string([])}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {10}, ...
                "FunctionNames", {[]}, ...
                "ModelName", {"gpt-4o-mini"}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"text"} ...
            ) ...
        ), ...
    "TopP", struct( ...
        "Input",{{"APIKey","this-is-not-a-real-key","TopP",0.2}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1}, ...
                "TopP", {0.2}, ...
                "StopSequences", {string([])}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {10}, ...
                "FunctionNames", {[]}, ...
                "ModelName", {"gpt-4o-mini"}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"text"} ...
            ) ...
        ), ...
    "StopSequences", struct( ...
        "Input",{{"APIKey","this-is-not-a-real-key","StopSequences",["foo","bar"]}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1}, ...
                "TopP", {1}, ...
                "StopSequences", {["foo","bar"]}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {10}, ...
                "FunctionNames", {[]}, ...
                "ModelName", {"gpt-4o-mini"}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"text"} ...
            ) ...
        ), ...
    "StopSequencesCharVector", struct( ...
        "Input",{{"APIKey","this-is-not-a-real-key","StopSequences",'supercalifragilistic'}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1}, ...
                "TopP", {1}, ...
                "StopSequences", {"supercalifragilistic"}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {10}, ...
                "FunctionNames", {[]}, ...
                "ModelName", {"gpt-4o-mini"}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"text"} ...
            ) ...
        ), ...
    "PresencePenalty", struct( ...
        "Input",{{"APIKey","this-is-not-a-real-key","PresencePenalty",0.1}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1}, ...
                "TopP", {1}, ...
                "StopSequences", {string([])}, ...
                "PresencePenalty", {0.1}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {10}, ...
                "FunctionNames", {[]}, ...
                "ModelName", {"gpt-4o-mini"}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"text"} ...
            ) ...
        ), ...
    "FrequencyPenalty", struct( ...
        "Input",{{"APIKey","this-is-not-a-real-key","FrequencyPenalty",0.1}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1}, ...
                "TopP", {1}, ...
                "StopSequences", {string([])}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0.1}, ...
                "TimeOut", {10}, ...
                "FunctionNames", {[]}, ...
                "ModelName", {"gpt-4o-mini"}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"text"} ...
            ) ...
        ), ...
    "TimeOut", struct( ...
        "Input",{{"APIKey","this-is-not-a-real-key","TimeOut",0.1}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1}, ...
                "TopP", {1}, ...
                "StopSequences", {string([])}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {0.1}, ...
                "FunctionNames", {[]}, ...
                "ModelName", {"gpt-4o-mini"}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"text"} ...
            ) ...
        ), ...
    "ResponseFormat", struct( ...
        "Input",{{"APIKey","this-is-not-a-real-key","ResponseFormat","json"}}, ...
        "ExpectedWarning", '', ...
        "VerifyProperties", struct( ...
                "Temperature", {1}, ...
                "TopP", {1}, ...
                "StopSequences", {string([])}, ...
                "PresencePenalty", {0}, ...
                "FrequencyPenalty", {0}, ...
                "TimeOut", {10}, ...
                "FunctionNames", {[]}, ...
                "ModelName", {"gpt-4o-mini"}, ...
                "SystemPrompt", {[]}, ...
                "ResponseFormat", {"json"} ...
            ) ...
        ) ...
    );
end

function invalidConstructorInput = iGetInvalidConstructorInput()
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
    "InvalidResponseFormatModelCombination", struct( ...
        "Input", {{"APIKey", "this-is-not-a-real-key", "ModelName", "gpt-4", "ResponseFormat", "json"}}, ...
        "Error", "llms:invalidOptionAndValueForModel"), ...
    ...
    "InvalidResponseFormatModelCombination2", struct( ...
        "Input", {{"APIKey", "this-is-not-a-real-key", "ModelName", "o1-mini", "ResponseFormat", "json"}}, ...
        "Error", "llms:invalidOptionAndValueForModel"), ...
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
    "InvalidModelNameType",struct( ...
        "Input",{{ "ModelName", 0 }},...
        "Error","MATLAB:validators:mustBeMember"),...
    ...
    "InvalidModelNameSize",struct( ...
        "Input",{{ "ModelName", ["gpt-4o-mini",  "gpt-4o-mini"] }},...
        "Error","MATLAB:validation:IncompatibleSize"),...
    ...
    "InvalidModelNameOption",struct( ...
        "Input",{{ "ModelName", "gpt" }},...
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
        "Error","MATLAB:validators:mustBeTextScalar"),...
    "StructuredOutputForWrongModel",struct( ...
        "Input",{{ "ModelName" "o1-preview" "ResponseFormat" struct("a", 1)}},...
        "Error","llms:noStructuredOutputForModel"));
end

function invalidGenerateInput = iGetInvalidGenerateInput()
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
            "Error","MATLAB:validators:mustBeTextScalar"),...
        ...
        "InvalidSeed",struct( ...
            "Input",{{ validMessages  "Seed" "2" }},...
            "Error","MATLAB:validators:mustBeNumeric"));   
end
