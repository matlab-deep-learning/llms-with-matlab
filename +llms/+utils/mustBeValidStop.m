function mustBeValidStop(value)
    if ~isempty(value)
        mustBeVector(value);
        mustBeNonzeroLengthText(value);
        % This restriction is set by the OpenAI API
        if numel(value)>4
            error("llms:stopSequencesMustHaveMax4Elements", llms.utils.errorMessageCatalog.getMessage("llms:stopSequencesMustHaveMax4Elements"));
        end
    end
end