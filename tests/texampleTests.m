classdef texampleTests < matlab.unittest.TestCase
% Smoke level tests for the example .mlx files

%   Copyright 2024 The MathWorks, Inc.

    methods (TestClassSetup)
        function setUpAndTearDowns(testCase)
            import matlab.unittest.fixtures.CurrentFolderFixture
            testCase.applyFixture(CurrentFolderFixture("../examples"));

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
    
    methods(Test)
        function testAnalyzeScientificPapersUsingFunctionCalls(~)
            AnalyzeScientificPapersUsingFunctionCalls;
        end

        function testProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode(~)
            ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode;
        end

        function testUsingDALLEToGenerateImages(~)
            UsingDALLEToGenerateImages;
        end

        function testInformationRetrievalUsingOpenAIDocumentEmbedding(~)
            InformationRetrievalUsingOpenAIDocumentEmbedding;
        end

        function testDescribeImagesUsingChatGPT(~)
            DescribeImagesUsingChatGPT;
        end

        function testSummarizeLargeDocumentsUsingChatGPTandMATLAB(~)
            SummarizeLargeDocumentsUsingChatGPTandMATLAB;
        end

        function testAnalyzeTextDataUsingParallelFunctionCallwithChatGPT(~)
            AnalyzeTextDataUsingParallelFunctionCallwithChatGPT;
        end

        function testRetrievalAugmentedGenerationUsingChatGPTandMATLAB(~)
            RetrievalAugmentedGenerationUsingChatGPTandMATLAB;
        end

        function testUsingDALLEToEditImages(~)
            UsingDALLEToEditImages;
        end

        function testAnalyzeSentimentinTextUsingChatGPTinJSONMode(testCase)
            testCase.verifyWarning(@AnalyzeSentimentinTextUsingChatGPTinJSONMode,...
                "llms:warningJsonInstruction");
        end

        function testCreateSimpleChatBot(testCase)
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
            CreateSimpleChatBot;

            testCase.verifyEqual(count,find(prompts=="end",1));
            testCase.verifySize(messages.Messages,[1 2*(count-1)]);
        end
    end
    
end

function iCloseAll()
% Close all opened figures
allFig = findall(0, 'type', 'figure');
close(allFig)
end
