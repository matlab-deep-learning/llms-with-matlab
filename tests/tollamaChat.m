classdef tollamaChat < hstructuredOutput & htoolCalls
% Tests for ollamaChat

%   Copyright 2024-2025 The MathWorks, Inc.

    properties(TestParameter)
        InvalidConstructorInput = iGetInvalidConstructorInput;
        InvalidGenerateInput = iGetInvalidGenerateInput;
        InvalidValuesSetters = iGetInvalidValuesSetters;
        ValidValuesSetters = iGetValidValuesSetters;
        StringInputs = struct('string',{"hi"},'char',{'hi'},'cellstr',{{'hi'}});
    end

    properties
        structuredModel = ollamaChat("mistral-nemo")
        defaultModel = ollamaChat("mistral-nemo")
        defaultModelName = "mistral-nemo"
        % htoolCalls wants to add arguments to the constructor calls
        constructor = @(varargin) ollamaChat("mistral-nemo", varargin{:})
    end

    methods (Test) % not calling the server
        function simpleConstruction(testCase)
            bot = ollamaChat(testCase.defaultModelName);
            testCase.verifyClass(bot,"ollamaChat");
        end

        function constructChatWithAllNVP(testCase)
            temperature = 0;
            topP = 1;
            stop = ["[END]", "."];
            systemPrompt = "This is a system prompt";
            timeout = 3;
            model = testCase.defaultModelName;
            chat = ollamaChat(model, systemPrompt, ...
                Temperature=temperature, TopP=topP, StopSequences=stop,...
                TimeOut=timeout);
            testCase.verifyEqual(chat.Temperature, temperature);
            testCase.verifyEqual(chat.TopP, topP);
            testCase.verifyEqual(chat.StopSequences, stop);
        end

        function sendsSystemPrompt(testCase)
            import matlab.unittest.constraints.HasField
            [sendRequestMock,sendRequestBehaviour] = ...
                createMock(testCase, AddedMethods="sendRequest");
            testCase.assignOutputsWhen( ...
                withAnyInputs(sendRequestBehaviour.sendRequest),...
                testCase.responseMessage("Hello"),"This output is unused with Stream=false");

            chat = testCase.constructor("You are a helpful assistant");
            chat.sendRequestFcn = @(varargin) sendRequestMock.sendRequest(varargin{:});

            response = testCase.verifyWarningFree(@() generate(chat,"Hi"));

            calls = testCase.getMockHistory(sendRequestMock);

            testCase.verifySize(calls,[1,1]);
            sentHistory = calls.Inputs{2};
            testCase.assertThat(sentHistory,HasField("messages"));
            testCase.verifyEqual(sentHistory.messages, ...
                { ...
                    struct(role="system",content="You are a helpful assistant"),...
                    struct(role="user",content="Hi") ...
                });
            testCase.verifyEqual(response,"Hello");
        end

        function extremeTopK(testCase)
            % As an end-to-end test, we should get the same response here for
            % repeated calls. That does seem to work reliably on some machines;
            % on others, Ollama receives the parameter, but either Ollama or
            % llama.cpp fails to honor it correctly. We only test that we send
            % the parameter correctly.
            import matlab.unittest.constraints.HasField
            [sendRequestMock,sendRequestBehaviour] = ...
                createMock(testCase, AddedMethods="sendRequest");
            testCase.assignOutputsWhen( ...
                withAnyInputs(sendRequestBehaviour.sendRequest),...
                testCase.responseMessage("Hello"),"This output is unused with Stream=false");

            % setting top-k to k=1 leaves no random choice,
            % so we expect to get a fixed response.
            chat = ollamaChat(testCase.defaultModelName,TopK=1);
            chat.sendRequestFcn = @(varargin) sendRequestMock.sendRequest(varargin{:});

            prompt = "Top-k sampling with k=1 returns a definite answer.";
            generate(chat,prompt);

            calls = testCase.getMockHistory(sendRequestMock);

            testCase.verifySize(calls,[1,1]);
            sentHistory = calls.Inputs{2};
            testCase.assertThat(sentHistory,HasField("options"));
            testCase.assertThat(sentHistory.options,HasField("top_k"));
            testCase.verifyEqual(sentHistory.options.top_k,1);
        end

        function extremeMinP(testCase)
            % As an end-to-end test, we should get the same response here for
            % repeated calls. That does seem to work reliably on some machines;
            % on others, Ollama receives the parameter, but either Ollama or
            % llama.cpp fails to honor it correctly. We only test that we send
            % the parameter correctly.
            import matlab.unittest.constraints.HasField
            [sendRequestMock,sendRequestBehaviour] = ...
                createMock(testCase, AddedMethods="sendRequest");
            testCase.assignOutputsWhen( ...
                withAnyInputs(sendRequestBehaviour.sendRequest),...
                testCase.responseMessage("Hello"),"This output is unused with Stream=false");

            % setting min-p to p=1 means only tokens with the same logit as
            % the most likely one can be chosen, which will almost certainly
            % only ever be one, so we expect to get a fixed response.
            chat = ollamaChat(testCase.defaultModelName,MinP=1);
            chat.sendRequestFcn = @(varargin) sendRequestMock.sendRequest(varargin{:});

            prompt = "Min-p sampling with p=1 returns a definite answer.";
            generate(chat,prompt);

            calls = testCase.getMockHistory(sendRequestMock);

            testCase.verifySize(calls,[1,1]);
            sentHistory = calls.Inputs{2};
            testCase.assertThat(sentHistory,HasField("options"));
            testCase.assertThat(sentHistory.options,HasField("min_p"));
            testCase.verifyEqual(sentHistory.options.min_p,1);
        end

        function extremeTfsZ(testCase)
            % As an end-to-end test, we should get the same response here for
            % repeated calls. That does seem to work reliably on some machines;
            % on others, Ollama receives the parameter, but either Ollama or
            % llama.cpp fails to honor it correctly. We only test that we send
            % the parameter correctly.
            import matlab.unittest.constraints.HasField
            [sendRequestMock,sendRequestBehaviour] = ...
                createMock(testCase, AddedMethods="sendRequest");
            testCase.assignOutputsWhen( ...
                withAnyInputs(sendRequestBehaviour.sendRequest),...
                testCase.responseMessage("Hello"),"This output is unused with Stream=false");

            % setting tfs_z to z=0 leaves no random choice, but degrades to
            % greedy sampling, so we expect to get a fixed response.
            chat = ollamaChat(testCase.defaultModelName,TailFreeSamplingZ=0);
            chat.sendRequestFcn = @(varargin) sendRequestMock.sendRequest(varargin{:});

            prompt = "Sampling with tfs_z=0 returns a definite answer.";
            generate(chat,prompt);

            calls = testCase.getMockHistory(sendRequestMock);

            testCase.verifySize(calls,[1,1]);
            sentHistory = calls.Inputs{2};
            testCase.assertThat(sentHistory,HasField("options"));
            testCase.assertThat(sentHistory.options,HasField("tfs_z"));
            testCase.verifyEqual(sentHistory.options.tfs_z,0);
        end

        function stopSequences(testCase)
            import matlab.unittest.constraints.HasField
            [sendRequestMock,sendRequestBehaviour] = ...
                createMock(testCase, AddedMethods="sendRequest");
            testCase.assignOutputsWhen( ...
                withAnyInputs(sendRequestBehaviour.sendRequest),...
                testCase.responseMessage("Hello"),"This output is unused with Stream=false");

            chat = ollamaChat(testCase.defaultModelName,StopSequences=["a" "b"]);
            chat.sendRequestFcn = @(varargin) sendRequestMock.sendRequest(varargin{:});

            prompt = "Top-k sampling with k=1 returns a definite answer.";
            generate(chat,prompt);

            calls = testCase.getMockHistory(sendRequestMock);

            testCase.verifySize(calls,[1,1]);
            sentHistory = calls.Inputs{2};
            testCase.assertThat(sentHistory,HasField("options"));
            testCase.assertThat(sentHistory.options,HasField("stop"));
            testCase.verifyEqual(sentHistory.options.stop,["a" "b"]);
        end

        function invalidInputsConstructor(testCase, InvalidConstructorInput)
            testCase.verifyError(@() ollamaChat(testCase.defaultModelName, InvalidConstructorInput.Input{:}), InvalidConstructorInput.Error);
        end

        function invalidInputsGenerate(testCase, InvalidGenerateInput)
            chat = testCase.defaultModel;
            testCase.verifyError(@() generate(chat,InvalidGenerateInput.Input{:}), InvalidGenerateInput.Error);
        end

        function invalidSetters(testCase, InvalidValuesSetters)
            chat = testCase.defaultModel;
            function assignValueToProperty(property, value)
                chat.(property) = value;
            end

            testCase.verifyError(@() assignValueToProperty(InvalidValuesSetters.Property,InvalidValuesSetters.Value), InvalidValuesSetters.Error);
        end

        function validSetters(testCase, ValidValuesSetters)
            chat = testCase.defaultModel;
            function assignValueToProperty(property, value)
                chat.(property) = value;
            end

            testCase.verifyWarningFree(@() assignValueToProperty(ValidValuesSetters.Property,ValidValuesSetters.Value));
        end

    end

    methods (Test) % calling the server, end-to-end tests
        function doGenerate(testCase,StringInputs)
            chat = testCase.defaultModel;
            response = testCase.verifyWarningFree(@() generate(chat,StringInputs));
            testCase.verifyClass(response,'string');
            testCase.verifyGreaterThan(strlength(response),0);
        end

        function generateOverridesProperties(testCase)
            import matlab.unittest.constraints.EndsWithSubstring
            chat = testCase.defaultModel;
            text = generate(chat, "Please count from 1 to 10.", Temperature = 0, StopSequences = "4");
            testCase.verifyThat(text, EndsWithSubstring("3, "));
        end

        function generateJSON(testCase)
            testCase.verifyClass( ...
                generate(testCase.defaultModel,"create some address, return json",ResponseFormat="json"), ...
                "string");
        end

        function generateWithToolsAndStreamFunc(testCase)
            % The test point in htoolCalls expects a format that is
            % different from what we get from Ollama. Having that
            % discrepancy isn't great, but for the moment, let's test what
            % we have instead.
            import matlab.unittest.constraints.HasField

            f = openAIFunction("writePaperDetails", "Function to write paper details to a table.");
            f = addParameter(f, "name", type="string", description="Name of the paper.");
            f = addParameter(f, "url", type="string", description="URL containing the paper.");
            f = addParameter(f, "explanation", type="string", description="Explanation on why the paper is related to the given topic.");

            paperExtractor = testCase.constructor( ...
                "You are an expert in extracting information from a paper.", ...
                Tools=f, StreamFun=@(s) s);

            input = join([
            "    <id>http://arxiv.org/abs/2406.04344v1</id>"
            "    <updated>2024-06-06T17:59:56Z</updated>"
            "    <published>2024-06-06T17:59:56Z</published>"
            "    <title>Verbalized Machine Learning: Revisiting Machine Learning with Language"
            "  Models</title>"
            "    <summary>  Motivated by the large progress made by large language models (LLMs), we"
            "introduce the framework of verbalized machine learning (VML). In contrast to"
            "conventional machine learning models that are typically optimized over a"
            "continuous parameter space, VML constrains the parameter space to be"
            "human-interpretable natural language. Such a constraint leads to a new"
            "perspective of function approximation, where an LLM with a text prompt can be"
            "viewed as a function parameterized by the text prompt. Guided by this"
            "perspective, we revisit classical machine learning problems, such as regression"
            "and classification, and find that these problems can be solved by an"
            "LLM-parameterized learner and optimizer. The major advantages of VML include"
            "(1) easy encoding of inductive bias: prior knowledge about the problem and"
            "hypothesis class can be encoded in natural language and fed into the"
            "LLM-parameterized learner; (2) automatic model class selection: the optimizer"
            "can automatically select a concrete model class based on data and verbalized"
            "prior knowledge, and it can update the model class during training; and (3)"
            "interpretable learner updates: the LLM-parameterized optimizer can provide"
            "explanations for why each learner update is performed. We conduct several"
            "studies to empirically evaluate the effectiveness of VML, and hope that VML can"
            "serve as a stepping stone to stronger interpretability and trustworthiness in"
            "ML."
            "</summary>"
            "    <author>"
            "      <name>Tim Z. Xiao</name>"
            "    </author>"
            "    <author>"
            "      <name>Robert Bamler</name>"
            "    </author>"
            "    <author>"
            "      <name>Bernhard Schölkopf</name>"
            "    </author>"
            "    <author>"
            "      <name>Weiyang Liu</name>"
            "    </author>"
            "    <arxiv:comment xmlns:arxiv='http://arxiv.org/schemas/atom'>Technical Report v1 (92 pages, 15 figures)</arxiv:comment>"
            "    <link href='http://arxiv.org/abs/2406.04344v1' rel='alternate' type='text/html'/>"
            "    <link title='pdf' href='http://arxiv.org/pdf/2406.04344v1' rel='related' type='application/pdf'/>"
            "    <arxiv:primary_category xmlns:arxiv='http://arxiv.org/schemas/atom' term='cs.LG' scheme='http://arxiv.org/schemas/atom'/>"
            "    <category term='cs.LG' scheme='http://arxiv.org/schemas/atom'/>"
            "    <category term='cs.CL' scheme='http://arxiv.org/schemas/atom'/>"
            "    <category term='cs.CV' scheme='http://arxiv.org/schemas/atom'/>"
            ], newline);

            topic = "Large Language Models";

            prompt =  "Given the following paper:" + newline + string(input)+ newline +...
                "Given the topic: "+ topic + newline + "Write the details to a table.";
            [~, ~, response] = generate(paperExtractor, prompt);

            % if the tool call works, which is not guaranteed to happen, we
            % will see a cell array here, with the first message a struct
            % containing a tool_call field.
            testCase.assumeClass(response.Body.Data,"cell");
            response_call = response.Body.Data{1}.message;
            testCase.assumeThat(response_call, HasField("tool_calls"));
            % Ollama does not have response_call.tool_calls.type == 'function' as returned by OpenAI
            testCase.verifyEqual(response_call.tool_calls.function.name,'writePaperDetails');
            % already decoded
            data = response_call.tool_calls.function.arguments;
            testCase.verifyEqual(sort(string(fieldnames(data))), ...
                sort(["name";"url";"explanation"]));
        end

        function seedFixesResult(testCase)
            %% This should work, and it does on some computers. On others, Ollama
            %% receives the parameter, but either Ollama or llama.cpp fails to
            %% honor it correctly.
            testCase.assumeFail("disabled due to Ollama/llama.cpp not honoring parameter reliably");

            chat = testCase.defaultModel;
            response1 = generate(chat,"hi",Seed=1234);
            response2 = generate(chat,"hi",Seed=1234);
            testCase.verifyEqual(response1,response2);
        end

        function generateWithImages(testCase)
            import matlab.unittest.constraints.ContainsSubstring
            chat = ollamaChat("moondream");
            image_path = "peppers.png";
            emptyMessages = messageHistory;
            messages = addUserMessageWithImages(emptyMessages,"What is in the image?",image_path);

            % The moondream model is small and unreliable. We are not
            % testing the model, we are testing that we send images to
            % Ollama in the right way. So we just ask several times and
            % are happy when  one of the responses mentions "pepper" or 
            % "vegetable".
            text = arrayfun(@(~) generate(chat,messages), 1:5, UniformOutput=false);
            text = join([text{:}],newline+"-----"+newline);
            testCase.verifyThat(text,ContainsSubstring("pepper") | ContainsSubstring("vegetable"));
        end

        function streamFunc(testCase)
            function seen = sf(str)
                persistent data;
                if isempty(data)
                    data = strings(1, 0);
                end
                % Append streamed text to an empty string array of length 1
                data = [data, str];
                seen = data;
            end
            chat = ollamaChat(testCase.defaultModelName, StreamFun=@sf);

            testCase.verifyWarningFree(@()generate(chat, "Hello world."));
            % Checking that persistent data, which is still stored in
            % memory, is greater than 1. This would mean that the stream
            % function has been called and streamed some text.
            testCase.verifyGreaterThan(numel(sf("")), 1);
        end

        function reactToEndpoint(testCase)
            testCase.assumeTrue(isenv("SECOND_OLLAMA_ENDPOINT"),...
                "Test point assumes a second Ollama server is running " + ...
                "and $SECOND_OLLAMA_ENDPOINT points to it.");
            chat = ollamaChat("qwen2:0.5b",Endpoint=getenv("SECOND_OLLAMA_ENDPOINT"));
            testCase.verifyWarningFree(@() generate(chat,"dummy"));
            % also make sure "http://" can be included
            chat = ollamaChat("qwen2:0.5b",Endpoint="http://" + getenv("SECOND_OLLAMA_ENDPOINT"));
            response = generate(chat,"some input");
            testCase.verifyClass(response,'string');
            testCase.verifyGreaterThan(strlength(response),0);
        end

        function doReturnErrors(testCase)
            testCase.assumeFalse( ...
                any(startsWith(ollamaChat.models,"abcdefghijklmnop")), ...
                "We want a model name that does not exist on this server");
            chat = ollamaChat("abcdefghijklmnop");
            testCase.verifyError(@() generate(chat,"hi!"), "llms:apiReturnedError");
        end

        function errorNoOllamaServer(testCase)
            % we expect no server running on this port
            chat = ollamaChat("mistral",Endpoint="127.0.0.1:11433");
            testCase.verifyError(@() generate(chat,"hi!"), "llms:noOllamaFound");
        end

        function queryModels(testCase)
            % our test setup has at least mistral-nemo loaded
            models = ollamaChat.models;
            testCase.verifyClass(models,"string");
            testCase.verifyThat(models, ...
                matlab.unittest.constraints.IsSupersetOf("mistral-nemo"));
        end
    end

    methods
        function msg = responseMessage(~,txt)
            % minimal structure replacing the real matlab.net.http.ResponseMessage() in our mocks
            msg = struct(...
                StatusCode="OK",...
                Body=struct(...
                    Data=struct(...
                        message=struct(...
                            content=txt))));
            end
    end
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
    "MinPTooLarge", struct( ...
        "Property", "MinP", ...
        "Value", 20, ...
        "Error", "MATLAB:notLessEqual"), ...
    ...
    "MinPTooSmall", struct( ...
        "Property", "MinP", ...
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
        "Error", "MATLAB:validators:mustBeNonzeroLengthText"));
end

function validSetters = iGetValidValuesSetters
validSetters = struct(...
    "SmallTopNum", struct( ...
        "Property", "TopK", ...
        "Value", 2));
    % Currently disabled because it requires some code reorganization
    % and we have higher priorities ...
    % "ManyStopSequences", struct( ...
    %     "Property", "StopSequences", ...
    %     "Value", ["1" "2" "3" "4" "5"]));
end

function invalidConstructorInput = iGetInvalidConstructorInput
invalidConstructorInput = struct( ...
    "InvalidResponseFormatValue", struct( ...
        "Input",{{"ResponseFormat", "foo" }},...
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
        "Error","MATLAB:expectedNonnegative"),...I
    ...
    "MinPTooLarge",struct( ...
        "Input",{{  "MinP" 20 }},...
        "Error","MATLAB:notLessEqual"),...
    ...
    "MinPTooSmall",struct( ...
        "Input",{{ "MinP" -20 }},...
        "Error","MATLAB:expectedNonnegative"),...I
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
        "Error","MATLAB:validators:mustBeNonzeroLengthText"));
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
            "Error","MATLAB:validators:mustBePositive"));
end

