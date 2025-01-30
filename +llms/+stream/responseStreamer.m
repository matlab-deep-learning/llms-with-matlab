classdef responseStreamer < matlab.net.http.io.BinaryConsumer
%responseStreamer Responsible for obtaining the streaming results from the
%API

%   Copyright 2023-2025 The MathWorks, Inc.

    properties
        ResponseText
        StreamFun
        Incomplete = ""
    end

    methods
        function this = responseStreamer(streamFun)
            this.StreamFun = streamFun;
        end
    end

    methods (Access=protected)
        function length = start(this)
            if this.Response.StatusCode ~= matlab.net.http.StatusCode.OK
                length = 0;
            else
                length = this.start@matlab.net.http.io.BinaryConsumer;
            end
        end
    end

    methods
        function [len,stop] = putData(this, data)
            [len,stop] = this.putData@matlab.net.http.io.BinaryConsumer(data);
            stop = doPutData(this, data, stop);
        end
    end

    methods (Access=?tresponseStreamer)
        function stop = doPutData(this, data, stop)
            % Extract out the response text from the message
            str = native2unicode(data','UTF-8');
            str = this.Incomplete + string(str);
            this.Incomplete = "";
            str = split(str,newline);
            str = str(strlength(str)>0);
            str = erase(str,"data: ");

            for i = 1:length(str)
                if strcmp(str{i},'[DONE]')
                    stop = true;
                    return
                else
                    try
                        json = jsondecode(str{i});
                    catch ME
                        if i == length(str)
                            this.Incomplete = str{i};
                            return;
                        end
                        error("llms:stream:responseStreamer:InvalidInput", ...
                            llms.utils.errorMessageCatalog.getMessage(...
                                "llms:stream:responseStreamer:InvalidInput", str{i}));
                    end
                    if isfield(json,'choices')
                        if isempty(json.choices)
                            continue;
                        end
                        if isfield(json.choices,'finish_reason') && ...
                                ischar(json.choices.finish_reason) && ismember(json.choices.finish_reason,["stop","tool_calls"])
                            stop = true;
                            return
                        else
                            if isfield(json.choices,"delta") && ...
                                    isfield(json.choices.delta,"tool_calls")
                                if isfield(json.choices.delta.tool_calls,"id")
                                    id = json.choices.delta.tool_calls.id;
                                    type = json.choices.delta.tool_calls.type;
                                    fcn = json.choices.delta.tool_calls.function;
                                    s = struct('id',id,'type',type,'function',fcn);
                                    txt = jsonencode(s);
                                else
                                    s = jsondecode(this.ResponseText);
                                    args = json.choices.delta.tool_calls.function.arguments;
                                    s.function.arguments = [s.function.arguments args];
                                    txt = jsonencode(s);
                                end
                                this.StreamFun('');
                                this.ResponseText = txt;
                            elseif isfield(json.choices,"delta") && ...
                                    isfield(json.choices.delta,"content")
                                txt = json.choices.delta.content;
                                this.StreamFun(txt);
                                this.ResponseText = [this.ResponseText txt];
                            end
                        end
                    else
                        txt = json.message.content;
                        if strlength(txt) > 0
                            this.StreamFun(txt);
                            this.ResponseText = [this.ResponseText txt];
                        end
                        if isfield(json.message,"tool_calls")
                            s = json.message.tool_calls;
                            txt = jsonencode(s);
                            this.StreamFun('');
                            this.ResponseText = [this.ResponseText txt];
                        end
                        if isfield(json,"done")
                            stop = json.done;
                        end
                    end
                end
            end
        end
    end
end