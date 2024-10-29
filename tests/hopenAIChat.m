classdef (Abstract) hopenAIChat < matlab.unittest.TestCase
% Tests for OpenAI-based chats (openAIChat, azureChat)

%   Copyright 2023-2024 The MathWorks, Inc.

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
        structuredModel
        noStructuredOutputModel
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

        function errorsWhenPassingToolChoiceWithEmptyTools(testCase)
            testCase.verifyError(@()generate(testCase.defaultModel,"input", ToolChoice="bla"), "llms:mustSetFunctionsForCall");
        end

        function settingToolChoiceWithNone(testCase)
            functions = openAIFunction("funName");
            chat = testCase.constructor(Tools=functions);

            testCase.verifyWarningFree(@()generate(chat,"This is okay","ToolChoice","none"));
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
            sf = @(x) fprintf("%s",x);
            chat = testCase.constructor(StreamFun=sf);
            result = generate(chat,"Why is a raven like a writing desk?",MaxNumTokens=5);
            testCase.verifyClass(result,"string");
            testCase.verifyLessThan(strlength(result), 100);
        end

        function generateWithToolsAndStreamFunc(testCase)
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
            [~, response] = generate(paperExtractor, prompt);

            testCase.assertThat(response, HasField("tool_calls"));
            testCase.verifyEqual(response.tool_calls.type,'function');
            testCase.verifyEqual(response.tool_calls.function.name,'writePaperDetails');
            data = testCase.verifyWarningFree( ...
                @() jsondecode(response.tool_calls.function.arguments));
            testCase.verifyThat(data,HasField("name"));
            testCase.verifyThat(data,HasField("url"));
            testCase.verifyThat(data,HasField("explanation"));
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

        function generateWithStructuredOutput(testCase)
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.StartsWithSubstring
            res = generate(testCase.structuredModel,"Which animal produces honey?",...
                ResponseFormat = struct(commonName = "dog", scientificName = "Canis familiaris"));
            testCase.assertClass(res,"struct");
            testCase.verifySize(fieldnames(res),[2,1]);
            testCase.verifyThat(res.commonName, IsEqualTo("Honeybee") | IsEqualTo("Honey bee")  | IsEqualTo("Honey Bee"));
            testCase.verifyThat(res.scientificName, StartsWithSubstring("Apis"));
        end

        function generateListWithStructuredOutput(testCase)
            prototype = struct("plantName",{"appletree","pear"}, ...
                "fruit",{"apple","pear"}, ...
                "edible",[true,true], ...
                "ignore", missing);
            res = generate(testCase.structuredModel,"What is harvested in August?", ResponseFormat = prototype);
            testCase.verifyCompatibleStructs(res, prototype);
        end

        function generateWithNestedStructs(testCase)
            stepsPrototype = struct("explanation",{"a","b"},"assumptions",{"a","b"});
            prototype = struct("steps",stepsPrototype,"final_answer","a");
            res = generate(testCase.structuredModel,"What is the positive root of x^2-2*x+1?", ...
                ResponseFormat=prototype);
            testCase.verifyCompatibleStructs(res,prototype);
        end

        function incompleteJSONResponse(testCase)
            country = ["USA";"UK"];
            capital = ["Washington, D.C.";"London"];
            population = [345716792;69203012];
            prototype = struct("country",country,"capital",capital,"population",population);

            testCase.verifyError(@() generate(testCase.structuredModel, ...
                "What are the five largest countries whose English names" + ...
                " start with the letter A?", ...
                ResponseFormat = prototype, MaxNumTokens=3), "llms:apiReturnedIncompleteJSON");
        end

        function generateWithExplicitSchema(testCase)
            import matlab.unittest.constraints.IsSameSetAs
            schema = iGetSchema();

            genUser = generate(testCase.structuredModel,"Create a sample user",ResponseFormat=schema);
            genAddress = generate(testCase.structuredModel,"Create a sample address",ResponseFormat=schema);
    
            testCase.verifyClass(genUser,"string");
            genUserDecoded = jsondecode(genUser);
            testCase.verifyClass(genUserDecoded.item,"struct");
            testCase.verifyThat(fieldnames(genUserDecoded.item),...
                IsSameSetAs({'name','age'}));
    
            testCase.verifyClass(genAddress,"string");
            genAddressDecoded = jsondecode(genAddress);
            testCase.verifyClass(genAddressDecoded.item,"struct");
            testCase.verifyThat(fieldnames(genAddressDecoded.item),...
                IsSameSetAs({'number','street','city'}));
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
            testCase.verifyError(@() generate(testCase.defaultModel,wayTooLong), "llms:apiReturnedError");
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

        function warningJSONResponseFormat(testCase)
            chat = @() testCase.constructor("You are a useful assistant", ...
                APIKey="this-is-not-a-real-key", ...
                ResponseFormat="json");

            testCase.verifyWarning(@()chat(), "llms:warningJsonInstruction");
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

    methods
        function verifyCompatibleStructs(testCase,data,prototype)
            import matlab.unittest.constraints.IsSameSetAs
            testCase.assertClass(data,"struct");
            if ~isscalar(data)
                arrayfun(@(d) testCase.verifyCompatibleStructs(d,prototype), data);
                return
            end
            testCase.assertClass(prototype,"struct");
            if ~isscalar(prototype)
                prototype = prototype(1);
            end
            testCase.assertThat(fieldnames(data),IsSameSetAs(fieldnames(prototype)));
            for name = fieldnames(data).'
                field = name{1};
                testCase.verifyClass(data.(field),class(prototype.(field)));
                if isstruct(data.(field))
                    testCase.verifyCompatibleStructs(data.(field),prototype.(field));
                end
            end
        end
    end
end

function str = iGetSchema()
% an example from https://platform.openai.com/docs/guides/structured-outputs/supported-schemas
str = string(join({
        '{'
        '    "type": "object",'
        '    "properties": {'
        '        "item": {'
        '            "anyOf": ['
        '                {'
        '                    "type": "object",'
        '                    "description": "The user object to insert into the database",'
        '                    "properties": {'
        '                        "name": {'
        '                            "type": "string",'
        '                            "description": "The name of the user"'
        '                        },'
        '                        "age": {'
        '                            "type": "number",'
        '                            "description": "The age of the user"'
        '                        }'
        '                    },'
        '                    "additionalProperties": false,'
        '                    "required": ['
        '                        "name",'
        '                        "age"'
        '                    ]'
        '                },'
        '                {'
        '                    "type": "object",'
        '                    "description": "The address object to insert into the database",'
        '                    "properties": {'
        '                        "number": {'
        '                            "type": "string",'
        '                            "description": "The number of the address. Eg. for 123 main st, this would be 123"'
        '                        },'
        '                        "street": {'
        '                            "type": "string",'
        '                            "description": "The street name. Eg. for 123 main st, this would be main st"'
        '                        },'
        '                        "city": {'
        '                            "type": "string",'
        '                            "description": "The city of the address"'
        '                        }'
        '                    },'
        '                    "additionalProperties": false,'
        '                    "required": ['
        '                        "number",'
        '                        "street",'
        '                        "city"'
        '                    ]'
        '                }'
        '            ]'
        '        }'
        '    },'
        '    "additionalProperties": false,'
        '    "required": ['
        '        "item"'
        '    ]'
        '}'
}, newline));
end
