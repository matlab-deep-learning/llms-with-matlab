%% Using ChatGPT with function calls
% This script automatically analyzes recent scientific papers from the
% ArXiv API, filtering papers based on the topic and using ChatGPT
% functions feature to extract relevant information on the papers.

%% Initialize OpenAI API Function and Chat
% Set up the function to store paper details and initiate a chat with the OpenAI API 
% with a defined role as a scientific paper expert.

% Define the function that you want the model to have access to. The
% function is defined at the end of the example.
f = openAIFunction("writePaperDetails", "Function to write paper details to a table.");
f = addParameter(f, "name", type="string", description="Name of the paper.");
f = addParameter(f, "url", type="string", description="URL containing the paper.");
f = addParameter(f, "explanation", type="string", description="Explanation on why the paper is related to the given topic.");

chat = openAIChat("You are an expert in filtering scientific papers. " + ...
    "Given a certain topic, you are able to decide if the paper" + ...
    " fits the given topic or not.", Functions=f);

%% Query ArXiv API for Recent Papers
% Specify the category of interest, the date range for the query, and the maximum 
% number of results to retrieve from the ArXiv API.

category = "cs.CL";
endDate = datetime("today", "Format","uuuuMMdd");
startDate = datetime("today", "Format","uuuuMMdd") - 5;
maxResults = 40;
urlQuery = "https://export.arxiv.org/api/query?search_query=" + ...
    "cat:" + category + ...
    "&submittedDate=["+string(startDate)+"+TO+"+string(endDate)+"]"+...
    "&max_results=" + maxResults + ...
    "&sortBy=submittedDate&sortOrder=descending";

options = weboptions('Timeout',160);
code = webread(urlQuery,options);

%% Extract Paper Entries and Filter by Topic
% Extract individual paper entries from the API response and use ChatGPT 
% to determine whether each paper is related to the specified topic.

pattern = '<entry>(.*?)</entry>';

% ChatGPT will parse the XML file, so we only need to extract the relevant
% entries.
matches = regexp(code, pattern, 'tokens');

% Determine the topic of interest
topic = "Embedding documents or sentences";

% Loop over the entries and see if they are relevant to the topic of
% interest.
for i = 1:length(matches)
    prompt =  "Given the following paper:" + newline +...
        string(matches{i})+ newline +...
        "Is it related to the topic: "+ topic +"?" + ...
        " Answer 'yes' or 'no'.";
    [text, response] = generate(chat, prompt);

    % If the model classifies this entry as relevant, then it tries to
    % request a function call.
    if contains("yes", text, IgnoreCase=true)
        prompt =  "Given the following paper:" + newline + string(matches{i})+ newline +...
            "Given the topic: "+ topic + newline + "Write the details to a table.";
        [text, response] = generate(chat, prompt);

        % If function_call if part of the response, it means the model is
        % requesting a function call. The function call request should
        % contain the needed arguments to call the function specified at
        % the end of this example and defined with openAIFunctions
        if isfield(response, "function_call")
            funCall = response.function_call;
            functionCallAttempt(funCall);
        end
    end
end

%% Function to Handle Function Call Attempts
% This function handles function call attempts from the model, checking 
% the function name and arguments before calling the appropriate function to 
% store the paper details.

function functionCallAttempt(funCall)
% The model can sometimes hallucinate function names, so you need to ensure
% that it's suggesting the correct name.
if funCall.name == "writePaperDetails"
    try
        % The model can sometimes return improperly formed JSON, which
        % needs to be handled
        funArgs = jsondecode(funCall.arguments);
    catch ME
        error("Model returned improperly formed JSON.");
    end
    % The model can hallucinate arguments. The code needs to ensure the
    % arguments have been defined before calling the function.
    if isfield(funArgs, "name") && isfield(funArgs, "url") && isfield(funArgs,"explanation")
        writePaperDetails(string(funArgs.name), string(funArgs.url), string(funArgs.explanation));
    end
end
end

%% Function to Write Paper Details to CSV File
% This function takes the details of a scientific paper and writes them to 
% a CSV file for further review.

function writePaperDetails(name, url, desc)
filename = "papers_to_read.csv";
T = table(name, url, desc, VariableNames=["Name", "URL", "Description"]);
writetable(T, filename, WriteMode="append");
end