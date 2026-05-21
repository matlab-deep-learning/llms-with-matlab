function result = webread(url, varargin)
% AnalyzeScientificPapersUsingFunctionCalls calls webread on arxiv.org,
% which aggressively rate-limits automated requests (HTTP 429). We stub
% arxiv responses with 36 minimal <entry> elements to match the recorded
% OpenAI call sequence. All other URLs pass through to the real webread.

if contains(url, "arxiv.org")
    entry = "<entry><id>http://arxiv.org/abs/0000.00000</id>" ...
        + "<title>Placeholder</title>" ...
        + "<summary>Placeholder summary.</summary></entry>";
    result = "<?xml version=""1.0""?><feed>" + join(repmat(entry, 1, 36), "") + "</feed>";
    result = char(result);
else
    thisDir = fileparts(mfilename("fullpath"));
    rmpath(thisDir);
    cleanup = onCleanup(@() addpath(thisDir));
    result = webread(url, varargin{:});
end
end
