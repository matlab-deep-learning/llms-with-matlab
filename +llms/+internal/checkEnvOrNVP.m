function key = checkEnvOrNVP(nvp)
    if isfield(nvp, "ApiKey")
        key = nvp.ApiKey;
    else
        if isenv("OPENAI_API_KEY")
            key = getenv("OPENAI_API_KEY");
        else
            error("llms:keyMustBeSpecified", llms.utils.errorMessageCatalog.getMessage("llms:keyMustBeSpecified"));
        end
    end
end