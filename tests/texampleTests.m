classdef texampleTests < matlab.unittest.TestCase
% Smoke level tests for the example .mlx files

%   Copyright 2024 The MathWorks, Inc.


    properties(TestParameter)
        ChatBotExample = {"CreateSimpleChatBot", "CreateSimpleOllamaChatBot"};
    end

    properties
        TestDir;
    end

    methods (TestClassSetup)
        function setUpAndTearDowns(testCase)
            % Capture and replay server interactions
            testCase.TestDir = fileparts(mfilename("fullpath"));
            import matlab.unittest.fixtures.PathFixture
            capture = false; % run in capture or replay mode, cf. recordings/README.md

            if capture
                testCase.applyFixture(PathFixture( ...
                    fullfile(testCase.TestDir,"private","recording-doubles")));
            else
                testCase.applyFixture(PathFixture( ...
                    fullfile(testCase.TestDir,"private","replaying-doubles")));
            end

            import matlab.unittest.fixtures.CurrentFolderFixture
            testCase.applyFixture(CurrentFolderFixture("../examples/mlx-scripts"));

            openAIEnvVar = "OPENAI_KEY";
            secretKey = getenv(openAIEnvVar);
            % Create an empty .env file because it is expected by our .mlx
            % example files
            writelines("",".env");
            
            % Assign the value of the secret key to OPENAI_API_KEY using
            % the test fixture
            import matlab.unittest.fixtures.EnvironmentVariableFixture
            fixture = EnvironmentVariableFixture("OPENAI_API_KEY", secretKey);
            testCase.applyFixture(fixture);

            testCase.addTeardown(@() iCloseAll());
        end
    end

    methods
        function startCapture(testCase,testName)
            llms.internal.sendRequestWrapper("open", ...
                fullfile(testCase.TestDir,"recordings",testName));
        end
    end

    methods(TestMethodTeardown)
        function closeCapture(~)
            llms.internal.sendRequestWrapper("close");
        end
    end

    methods(Test)
        function testAnalyzeScientificPapersUsingFunctionCalls(testCase)
            testCase.startCapture("AnalyzeScientificPapersUsingFunctionCalls");
            AnalyzeScientificPapersUsingFunctionCalls;
        end

        function testAnalyzeSentimentinTextUsingChatGPTinJSONMode(testCase)
            testCase.startCapture("AnalyzeSentimentinTextUsingChatGPTinJSONMode");
            testCase.verifyWarning(@AnalyzeSentimentinTextUsingChatGPTinJSONMode,...
                "llms:warningJsonInstruction");
        end

        function testAnalyzeTextDataUsingParallelFunctionCallwithChatGPT(testCase)
            testCase.startCapture("AnalyzeTextDataUsingParallelFunctionCallwithChatGPT");
            AnalyzeTextDataUsingParallelFunctionCallwithChatGPT;
        end

        function testCreateSimpleChatBot(testCase,ChatBotExample)
            testCase.startCapture(ChatBotExample);
            % set up a fake input command, returning canned user prompts
            count = 0;
            prompts = [
                "Hello, how much do you know about physics?"
                "What is torque?"
                "What is force?"
                "What is motion?"
                "What is time?"
                "end"
                "end"
                "end"
            ];
            function res = input_(varargin)
                count = count + 1;
                res = prompts(count);
            end
            input = @input_; %#ok<NASGU>

            % to avoid errors about a static workspace, let MATLAB know we
            % want these variables to exist
            wordLimit = []; %#ok<NASGU>
            stopWord = []; %#ok<NASGU>
            modelName = []; %#ok<NASGU>
            chat = []; %#ok<NASGU>
            messages = [];
            totalWords = []; %#ok<NASGU>
            messagesSizes = []; %#ok<NASGU>
            query = []; %#ok<NASGU>
            numWordsQuery = []; %#ok<NASGU>
            text = []; %#ok<NASGU>
            response = []; %#ok<NASGU>
            numWordsResponse = []; %#ok<NASGU>

            % Run the example
            eval(ChatBotExample);

            testCase.verifyEqual(count,find(prompts=="end",1));
            testCase.verifySize(messages.Messages,[1 2*(count-1)]);
        end

        function testDescribeImagesUsingChatGPT(testCase)
            testCase.startCapture("DescribeImagesUsingChatGPT");
            DescribeImagesUsingChatGPT;
        end

        function testInformationRetrievalUsingOpenAIDocumentEmbedding(testCase)
            testCase.startCapture("InformationRetrievalUsingOpenAIDocumentEmbedding");
            InformationRetrievalUsingOpenAIDocumentEmbedding;
        end

        function testProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode(testCase)
            testCase.startCapture("ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode");
            ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode;
        end

        function testProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode(testCase)
            testCase.startCapture("ProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode");
            ProcessGeneratedTextInRealTimeByUsingOllamaInStreamingMode;
        end

        function testRetrievalAugmentedGenerationUsingChatGPTandMATLAB(testCase)
            testCase.startCapture("RetrievalAugmentedGenerationUsingChatGPTandMATLAB");
            RetrievalAugmentedGenerationUsingChatGPTandMATLAB;
        end

        function testRetrievalAugmentedGenerationUsingOllamaAndMATLAB(testCase)
            testCase.startCapture("RetrievalAugmentedGenerationUsingOllamaAndMATLAB");
            RetrievalAugmentedGenerationUsingOllamaAndMATLAB;
        end

        function testSummarizeLargeDocumentsUsingChatGPTandMATLAB(testCase)
            testCase.startCapture("SummarizeLargeDocumentsUsingChatGPTandMATLAB");
            SummarizeLargeDocumentsUsingChatGPTandMATLAB;
        end

        function testUsingDALLEToEditImages(testCase)
            testCase.startCapture("UsingDALLEToEditImages");
            UsingDALLEToEditImages;
        end

        function testUsingDALLEToGenerateImages(testCase)
            testCase.startCapture("UsingDALLEToGenerateImages");
            UsingDALLEToGenerateImages;
        end
    end    
end

function iCloseAll()
% Close all opened figures
allFig = findall(0, 'type', 'figure');
close(allFig)
end
