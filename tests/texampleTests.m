classdef texampleTests < matlab.unittest.TestCase
% Smoke level tests for the example .mlx files

%   Copyright 2024 The MathWorks, Inc.

    methods (TestClassSetup)
        function saveEnvVar(testCase)
            % Ensures key is not in environment variable for tests
            openAIEnvVar = "OPENAI_KEY";
            key = getenv(openAIEnvVar);
            unsetenv(openAIEnvVar);
            testCase.addTeardown(@(x) setenv(openAIEnvVar, x), key);
        end
    end
    
    methods(Test)
        % Test methods

        function testAnalyzeScientificPapersUsingFunctionCalls(~)
            AnalyzeScientificPapersUsingFunctionCalls;
        end
    end
    
end