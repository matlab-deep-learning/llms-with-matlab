classdef texampleTests < matlab.unittest.TestCase
% Smoke level tests for the example .mlx files

%   Copyright 2024 The MathWorks, Inc.

    methods (TestClassSetup)
        function saveEnvVar(testCase)
            openAIEnvVar = "OPENAI_KEY";
            key = getenv(openAIEnvVar);
            writelines("OPENAI_API_KEY="+key,".env");
            
            testCase.addTeardown(@() delete(".env"));
            testCase.addTeardown(@() unsetenv("OPENAI_API_KEY"));
        end
    end
    
    methods(Test)
        function testAnalyzeScientificPapersUsingFunctionCalls(~)
            AnalyzeScientificPapersUsingFunctionCalls;
        end
    end
    
end