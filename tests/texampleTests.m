classdef texampleTests < matlab.unittest.TestCase
% Smoke level tests for the example .mlx files

%   Copyright 2024 The MathWorks, Inc.

    methods (TestClassSetup)
        function setUpAndTearDowns(testCase)
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

        function testAnalyzeSentimentinTextUsingChatGPTinJSONMode(~)
            AnalyzeSentimentinTextUsingChatGPTinJSONMode;
        end

        function testUsingDALLEToEditImages(~)
            UsingDALLEToEditImages;
        end
    end
    
end

function iCloseAll()
% Close all opened figures
allFig = findall(0, 'type', 'figure');
close(allFig)
end