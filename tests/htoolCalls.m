classdef (Abstract) htoolCalls < matlab.unittest.TestCase
% Tests for backends with tool calls

%   Copyright 2023-2025 The MathWorks, Inc.
    properties(Abstract)
        constructor
        defaultModel
    end
    
    methods(Test)
        function errorsWhenPassingToolChoiceWithEmptyTools(testCase)
            testCase.verifyError(@()generate(testCase.defaultModel,"input", ToolChoice="bla"), "llms:mustSetFunctionsForCall");
        end

        function settingToolChoiceWithNone(testCase)
            functions = openAIFunction("funName");
            chat = testCase.constructor(Tools=functions);

            testCase.verifyWarningFree(@()generate(chat,"This is okay","ToolChoice","none"));
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
    end
end
