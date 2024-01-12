# Policija

Policija je web aplikacija razvijena kao dio projekta za kolegij Baze podataka 2 na Fakultetu informatike u Puli.

## Installation

Follow these steps to install and run the Policija app locally:

1. Clone the repository:
    ```bash
    git clone https://github.com/petarally/BP2_policija_aplikacija.git
    cd policija
    ```

2. Create a virtual environment and activate it:

    On Windows, run:
    ```bash
    python -m venv venv
    .\venv\Scripts\activate
    ```

    On Unix or MacOS, run:
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

3. Install the requirements:
    ```bash
    pip install -r requirements.txt
    ```

4. Run the application:
    ```bash
    python app.py
    ```

Now, you should be able to see the application running at `http://127.0.0.1:8000/` in your web browser.
