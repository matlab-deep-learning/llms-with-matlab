classdef topenAIMessages < matlab.unittest.TestCase
% Tests for openAIMessages backward compatibility function

%   Copyright 2023-2024 The MathWorks, Inc.

methods(Test)
    function returnsMessageHistory(testCase)
        testCase.verifyClass(openAIMessages,"messageHistory");
    end
end
end
