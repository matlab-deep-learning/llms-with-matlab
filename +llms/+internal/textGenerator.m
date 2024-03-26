classdef (Abstract) textGenerator
    
    properties   
        %TEMPERATURE   Temperature of generation.
        Temperature

        %TOPPROBABILITYMASS   Top probability mass to consider for generation.
        TopProbabilityMass

        %STOPSEQUENCES   Sequences to stop the generation of tokens.
        StopSequences

        %PRESENCEPENALTY   Penalty for using a token in the response that has already been used.
        PresencePenalty

        %FREQUENCYPENALTY   Penalty for using a token that is frequent in the training data.
        FrequencyPenalty
    end
    
    properties (SetAccess=protected)
        %TIMEOUT    Connection timeout in seconds (default 10 secs)
        TimeOut

        %FUNCTIONNAMES   Names of the functions that the model can request calls
        FunctionNames

        %SYSTEMPROMPT   System prompt.
        SystemPrompt = []

        %RESPONSEFORMAT     Response format, "text" or "json"       
        ResponseFormat
    end
    
    properties (Access=protected)
        Tools
        FunctionsStruct
        ApiKey
        StreamFun
    end


    methods      
        function this = set.Temperature(this, temperature)
            arguments
                this
                temperature 
            end
            llms.utils.mustBeValidTemperature(temperature);
            this.Temperature = temperature;
        end

        function this = set.TopProbabilityMass(this,topP)
            arguments
                this
                topP
            end
            llms.utils.mustBeValidTopP(topP);
            this.TopProbabilityMass = topP;
        end

        function this = set.StopSequences(this,stop)
            arguments
                this
                stop 
            end
            llms.utils.mustBeValidStop(stop);
            this.StopSequences = stop;
        end

        function this = set.PresencePenalty(this,penalty)
            arguments
                this
                penalty 
            end
            llms.utils.mustBeValidPenalty(penalty)
            this.PresencePenalty = penalty;
        end

        function this = set.FrequencyPenalty(this,penalty)
            arguments
                this
                penalty
            end
            llms.utils.mustBeValidPenalty(penalty)
            this.FrequencyPenalty = penalty;
        end

    end

end