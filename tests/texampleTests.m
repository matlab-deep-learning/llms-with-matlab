classdef texampleTests < matlab.unittest.TestCase
% Smoke level tests for the example .mlx files

%   Copyright 2024 The MathWorks, Inc.

    methods (TestClassSetup)
        function setUpAndTearDowns(testCase)
            openAIEnvVar = "OPENAI_KEY";
            key = getenv(openAIEnvVar);
            writelines("OPENAI_API_KEY="+key,".env");

            testCase.addTeardown(@() delete(".env"));
            testCase.addTeardown(@() unsetenv("OPENAI_API_KEY"));
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
    end
    
end

function iCloseAll()
% Close all opened figures
allFig = findall(0, 'type', 'figure');
close(allFig)
end