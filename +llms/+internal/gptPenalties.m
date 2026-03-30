classdef (Abstract) gptPenalties
    % This class is undocumented and will change in a future release

    % Copyright 2024-2026 The MathWorks, Inc.
    properties
        %PRESENCEPENALTY   Penalty for using a token in the response that has already been used.
        PresencePenalty {llms.utils.mustBeValidPenalty} = "auto"

        %FREQUENCYPENALTY   Penalty for using a token that is frequent in the training data.
        FrequencyPenalty {llms.utils.mustBeValidPenalty} = "auto"
    end

    methods
        function hObj = set.PresencePenalty(hObj,value)
            hObj.PresencePenalty = convertCharsToStrings(value);
        end

        function hObj = set.FrequencyPenalty(hObj,value)
            hObj.FrequencyPenalty = convertCharsToStrings(value);
        end
    end
end
