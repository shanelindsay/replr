# Exploring replr CLI with mtcars

This document demonstrates the `clir.sh` Bash client shipped with **replr**. Each section shows the command and the resulting output when run in a shell. Ensure the `myr` environment is active before running the examples.

```bash
micromamba activate myr
```

## Starting and listing a server

Start a new instance labelled `demo` on port `8123` and confirm it is tracked under `~/.replr/instances`.

```bash
$ tools/clir.sh start demo 8123
Started 'demo' on port 8123 (PID 12345)

$ tools/clir.sh list
demo:8123:12345
```

## Basic evaluation

Pipe an expression to `exec` for evaluation. By default plain text is returned
and includes a small summary of the result.

```bash
$ echo 'mean(mtcars$mpg)' | tools/clir.sh exec demo
[1] 20.09062
List of 1
 $ type: chr "double"
```

Request JSON instead using `--json`.

```bash
$ echo 'mean(mtcars$mpg)' | tools/clir.sh exec demo --json
{
  "status": "success",
  "output": "",
  "error": "",
  "plots": [],
  "result_summary": {"type": "double"}
}
```

## Working with data frames

Summaries of data frames include a small preview controlled by the `replr.preview_rows` option.

```bash
$ tools/clir.sh exec demo -e 'head(mtcars)'
   mpg cyl disp  hp drat    wt  qsec vs am gear carb
1 21.0   6  160 110 3.90 2.620 16.46  0  1    4    4
2 21.0   6  160 110 3.90 2.875 17.02  0  1    4    4
3 22.8   4  108  93 3.85 2.320 18.61  1  1    4    1
4 21.4   6  258 110 3.08 3.215 19.44  1  0    3    1
5 18.7   8  360 175 3.15 3.440 17.02  0  0    3    2
List of 4
 $ type   : chr "data.frame"
 $ dim    : int [1:2] 6 11
 $ columns: chr [1:11] "mpg" "cyl" "disp" "hp" ...
 $ preview:List of 5
```

Structured JSON can be requested for machine processing:

```bash
$ tools/clir.sh exec demo -e 'head(mtcars)' --json
{
  "status": "success",
  "output": "",
  "error": "",
  "plots": [],
  "result_summary": {
    "type": "data.frame",
    "dim": [6, 11],
    "columns": ["mpg", "cyl", "disp", "hp", "drat", "wt", "qsec", "vs", "am", "gear", "carb"],
    "preview": [
      {"mpg": 21, "cyl": 6, "disp": 160, "hp": 110, "drat": 3.9, "wt": 2.62, "qsec": 16.46, "vs": 0, "am": 1, "gear": 4, "carb": 4},
      {"mpg": 21, "cyl": 6, "disp": 160, "hp": 110, "drat": 3.9, "wt": 2.875, "qsec": 17.02, "vs": 0, "am": 1, "gear": 4, "carb": 4},
      {"mpg": 22.8, "cyl": 4, "disp": 108, "hp": 93, "drat": 3.85, "wt": 2.32, "qsec": 18.61, "vs": 1, "am": 1, "gear": 4, "carb": 1},
      {"mpg": 21.4, "cyl": 6, "disp": 258, "hp": 110, "drat": 3.08, "wt": 3.215, "qsec": 19.44, "vs": 1, "am": 0, "gear": 3, "carb": 1},
      {"mpg": 18.7, "cyl": 8, "disp": 360, "hp": 175, "drat": 3.15, "wt": 3.44, "qsec": 17.02, "vs": 0, "am": 0, "gear": 3, "carb": 2}
    ]
  }
}
```

## Fitting a model

Model objects return key statistics in the summary.

```bash
$ tools/clir.sh exec demo -e 'lm(mpg ~ wt + hp, data = mtcars)' --json
{
  "status": "success",
  "output": "",
  "error": "",
  "plots": [],
  "result_summary": {
    "type": "lm",
    "formula": "mpg ~ wt + hp",
    "r_squared": 0.8268,
    "coefficients": {
      "(Intercept)": 37.22727,
      "wt": -3.87783,
      "hp": -0.03177
    }
  }
}
```

## Generating plots

If a command produces a plot, the path is printed even in plain text mode.

```bash
$ tools/clir.sh exec demo -e 'plot(mtcars$wt, mtcars$mpg)'
demo/images/plot_20250619_120000_1.png
List of 1
 $ type: chr "NULL"
```

```bash
$ tools/clir.sh exec demo -e 'plot(mtcars$wt, mtcars$mpg)' --json
  {
    "status": "success",
    "output": "",
    "error": "",
  "plots": ["demo/images/plot_20250619_120000_1.png"],
  "result_summary": {"type": "NULL"}
}
```

The PNG file can be viewed directly or served elsewhere.

## Handling warnings and errors

When code triggers a warning, it is reported along with the result:

```bash
$ echo 'sqrt(-1)' | tools/clir.sh exec demo
[1] NaN
Warnings: NaNs produced
List of 1
 $ type: chr "double"
```

```bash
$ echo 'sqrt(-1)' | tools/clir.sh exec demo --json
{
  "status": "success",
  "output": "",
  "error": "",
  "warning": ["NaNs produced"],
  "plots": [],
  "result_summary": {"type": "double"}
}
```

Errors set the status to "error":

```bash
$ echo 'log("a")' | tools/clir.sh exec demo
Error: non-numeric argument to mathematical function
```

```bash
$ echo 'log("a")' | tools/clir.sh exec demo --json
{
  "status": "error",
  "output": "",
  "error": "non-numeric argument to mathematical function",
  "warning": [],
  "plots": []
}
```

## Checking status and shutting down

Check that the server is running and then stop it when finished.

```bash
$ tools/clir.sh status demo
{"status":"running","uptime":42.5,"pid":12345,"r_version":"R version 4.4.3 (2025-02-28)"}

$ tools/clir.sh stop demo
Sent shutdown to 'demo' (port 8123)
```

---

These examples illustrate the core features of the CLI: starting and stopping instances, executing code with text or JSON output, inspecting data frames and models, retrieving plot images, and handling warnings or errors. All examples used the built-in `mtcars` dataset.
