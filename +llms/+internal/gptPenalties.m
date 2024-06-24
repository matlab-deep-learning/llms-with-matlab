classdef (Abstract) gptPenalties
    % This class is undocumented and will change in a future release

    % Copyright 2024 The MathWorks, Inc.
    properties
        %PRESENCEPENALTY   Penalty for using a token in the response that has already been used.
        PresencePenalty {llms.utils.mustBeValidPenalty} = 0

        %FREQUENCYPENALTY   Penalty for using a token that is frequent in the training data.
        FrequencyPenalty {llms.utils.mustBeValidPenalty} = 0
    end
end
