
# Process Generated Text in Real Time by Using ChatGPT™ in Streaming Mode

To run the code shown on this page, open the MLX file in MATLAB: [mlx-scripts/ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode.mlx](mlx-scripts/ProcessGeneratedTextinRealTimebyUsingChatGPTinStreamingMode.mlx) 

This example shows how to process generated text in real time by using ChatGPT in streaming mode.


By default, when you pass a prompt to ChatGPT, it generates a response internally and then outputs it in full at the end. To print out and format generated text as the model is generating it, use the `StreamFun` name\-value argument of the `openAIChat` class. The streaming function is a custom function handle that tells the model what to do with the output.


The example includes two parts:

-  First, define and use a custom streaming function to print out generated text directly as the model generates it. 
-  Then, create an HTML UI Component and define and use a custom streaming function to update the UI Component in real time as the model generates text. 

To run this example, you need a valid API key from a paid OpenAI™ API account.

```matlab
loadenv(".env")
addpath('../..') 
```
# Print Stream Directly to Screen

In this example, the streamed output is printed directly to the screen. 


Define the function to print the returned tokens. 

```matlab
function printToken(token)
    fprintf("%s",token);
end
```

Create the chat object with the defined function as a handle. 

```matlab
chat = openAIChat(StreamFun=@printToken);
```

Generate response to a prompt in streaming mode. 

```matlab
prompt = "What is Model-Based Design?";
generate(chat, prompt, MaxNumTokens=500);
```

```matlabTextOutput
Model-Based Design is an approach to system development that uses graphical models to design and simulate systems before implementing them in hardware or software. It involves creating models that represent the behavior and interactions of system components, and using these models to analyze, validate, and optimize the system before building it. Model-Based Design can help to improve the efficiency, reliability, and quality of system development by enabling engineers to explore design alternatives, detect errors early in the development process, and facilitate collaboration between different teams working on the same project.
```
# Print Stream to HTML UI Component

In this example, the streamed output is printed to the HTML component. 


Create the HTML UI component.

```matlab
fig = uifigure;
h = uihtml(fig,Position=[50,10,450,400]);
```

Initialize the content of the HTML UI component.

```matlab
resetTable(h);
```

Create the chat object with the function handle, which requires the `uihtml` object created earlier. 

```matlab
chat = openAIChat(StreamFun=@(x)printStream(h,x));
```

Add the user prompt to the table in the HTML UI component.

```matlab
userPrompt = "Tell me 5 jokes.";
addChat(h,"user",userPrompt,"new")
```

Generate response to a prompt in streaming mode. 

```matlab
[txt, message, response] = generate(chat,userPrompt);
```

Update the last row with the final output. This is necessary if further update is needed to support additional HTML formatting.

```matlab
addChat(h,"assistant",txt,"current")
```
# Helper functions

`resetTable`:

1.  Adds the basic HTML structure and the JavaScript that process the data change in MATLAB.
2. The JavaScript gets a reference to the table and changed data and if the 3rd element in the data is "new", adds a new row.
3. It populates the new row with two cells and update the cells from the first two elements of the data.
4. The new row is then appended to the table.
5. Otherwise, the JavaScript gets reference to the last cell of the last row of the table, and update it with the 2nd element of the data.
```matlab
function resetTable(obj)
    %RESETTABLE initialize the HTML UI component in the input argument.  
    mustBeA(obj,'matlab.ui.control.HTML')
    obj.HTMLSource =  ['<html><body><table>' ...
        '<tr><th>Role</th><th>Content</th></tr></table><script>', ...
        'function setup(htmlComponent) {', ...
        'htmlComponent.addEventListener("DataChanged", function(event) {', ... 
        'var table = document.querySelector("table");' ...
        'var changedData = htmlComponent.Data;', ...
        'if (changedData[2] == "new") {', ...
        'var newRow = document.createElement("tr");', ...
        'var cell1 = document.createElement("td");', ...                    
        'var cell2 = document.createElement("td");', ...
        'cell1.innerHTML = changedData[0];', ...
        'cell2.innerHTML = changedData[1];', ... 
        'newRow.appendChild(cell1);', ...
        'newRow.appendChild(cell2);', ...
        'table.appendChild(newRow);', ...
        '} else { ', ...
        'var lastRow = table.rows[table.rows.length - 1];', ...
        'var lastCell = lastRow.cells[lastRow.cells.length - 1];', ...
        'lastCell.innerHTML = changedData[1];', ...
        '}});}</script></body></html>'];
    obj.Data = [];
    drawnow
end
```

`addRow` adds a new row to the table in the HTML UI component

```matlab
function addChat(obj,role,content,row)
    %ADDCHAT adds a new row or updates the last row of the table
    mustBeA(obj,'matlab.ui.control.HTML')
    content = replace(content,newline,"<br>");
    obj.Data = {role,content,row};
    drawnow
end
```

`printStream` is the streaming function and prints the stream in the table in the HTML UI component

```matlab
function printStream(h,x)
    %PRINTSTREAM prints the stream in a new row in the table
    if strlength(x) == 0
        % if the first token is 0 length, add a new row
        tokens = string(x);
        h.Data = {"assistant",tokens,"new"};
    else
        % otherwise append the new token to the previous tokens
        % if the new token contains a line break, replace 
        % it with <br>
        if contains(x,newline)
            x = replace(x,newline,"<br>");
        end
        tokens = h.Data{2} + string(x);
        % update the existing row. 
        h.Data = {"assistant",tokens,"current"};
    end
    drawnow
end
```

*Copyright 2024 The MathWorks, Inc.*

