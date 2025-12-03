
# Analyze Scientific Papers Using ChatGPT™ Function Calls

To run the code shown on this page, open the MLX file in MATLAB®: [mlx-scripts/AnalyzeScientificPapersUsingFunctionCalls.mlx](mlx-scripts/AnalyzeScientificPapersUsingFunctionCalls.mlx) 

This example shows how to extract recent scientific papers from ArXiv, summarize them using ChatGPT, and write the results to a CSV file using the `openAIFunction` function.

-  The example contains three steps: 
-  Define a custom function for ChatGPT to use to process its input and output. 
-  Extract papers from ArXiv. 
-  Use ChatGPT to assess whether a paper is relevant to your query, and to add an entry to the results table if so. 

To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
```
# Initialize OpenAI API Function and Chat

Use `openAIFunction` to define functions that the model will be able to requests calls. 


Set up the function to store paper details and initiate a chat with the OpenAI API with a defined role as a scientific paper expert.


Define the function that you want the model to have access to. In this example the used function is `writePaperDetails`.


This example uses the model gpt\-4.1\-mini.

```matlab
f = openAIFunction("writePaperDetails", "Function to write paper details to a table.");
f = addParameter(f, "name", type="string", description="Name of the paper.");
f = addParameter(f, "url", type="string", description="URL containing the paper.");
f = addParameter(f, "explanation", type="string", description="Explanation on why the paper is related to the given topic.");

paperVerifier = openAIChat("You are an expert in filtering scientific papers. " + ...
    "Given a certain topic, you are able to decide if the paper" + ...
    " fits the given topic or not.", ModelName="gpt-4.1-mini");

paperExtractor = openAIChat("You are an expert in extracting information from a paper.", Tools=f, ModelName="gpt-4.1-mini");

function writePaperDetails(name, url, desc)
filename = "papers_to_read.csv";
T = table(name, url, desc, VariableNames=["Name", "URL", "Description"]);
writetable(T, filename, WriteMode="append");
end
```
# Extract Papers From ArXiv

Specify the category of interest, the date range for the query, and the maximum number of results to retrieve from the ArXiv API.

```matlab
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
```

Extract individual paper entries from the API response and use ChatGPT to determine whether each paper is related to the specified topic.


ChatGPT will parse the XML file, so we only need to extract the relevant entries.

```matlab
entries = extractBetween(code, '<entry>', '</entry>');
```
# Write Relevant Information to Table

Create empty file and determine the topic of interest.

```matlab
filename = "papers_to_read.csv";
T = table([], [], [], VariableNames=["Name", "URL", "Description"]);
writetable(T, filename);

topic = "Large Language Models";
```

Loop over the entries and see if they are relevant to the topic of interest.

```matlab
for i = 1:length(entries)
    prompt =  "Given the following paper:" + newline +...
        string(entries{i})+ newline +...
        "Is it related to the topic: "+ topic +"?" + ...
        " Answer 'yes' or 'no'.";
    [text, response] = generate(paperVerifier, prompt);

```

If the model classifies this entry as relevant, then it tries to request a function call.

```matlab
    if contains("yes", text, IgnoreCase=true)
        prompt =  "Given the following paper:" + newline + string(entries{i})+ newline +...
            "Given the topic: "+ topic + newline + "Write the details to a table.";
        [text, response] = generate(paperExtractor, prompt);
```

If `function_call` if part of the response, it means the model is requesting a function call. The function call request should contain the needed arguments to call the function specified at the end of this example and defined with `openAIFunctions`.

```matlab
        if isfield(response, "tool_calls")
            funCall = response.tool_calls;
            functionCallAttempt(funCall);
        end
    end
end
```

Read the generated file. 

```matlab
data = readtable("papers_to_read.csv", Delimiter=",")
```
# Helper Function

This function handles function call attempts from the model, checking the function name and arguments before calling the appropriate function to store the paper details.

```matlab
function functionCallAttempt(funCall)
```

The model can sometimes hallucinate function names, so you need to ensure that it's suggesting the correct name.

```matlab
if funCall.function.name == "writePaperDetails"
    try
```

The model can sometimes return improperly formed JSON, which needs to be handled.

```matlab
        funArgs = jsondecode(funCall.function.arguments);
    catch ME
        error("Model returned improperly formed JSON.");
    end
```

The model can hallucinate arguments. The code needs to ensure the arguments have been defined before calling the function.

```matlab
    if isfield(funArgs, "name") && isfield(funArgs, "url") && isfield(funArgs,"explanation")
        writePaperDetails(string(funArgs.name), string(funArgs.url), string(funArgs.explanation));
    end
end
end
```

*Copyright 2023\-2024 The MathWorks, Inc.*

