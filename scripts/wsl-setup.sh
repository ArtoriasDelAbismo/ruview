
#!/bin/bash
echo "Cloning RuView..."
git clone https://github.com/ruvnet/RuView.git core
echo "Creating virtual environment..."
python3 -m venv venv && source venv/bin/activate
echo "Installing minimal dependencies..."
pip3 install -r requirements-minimal.txt --break-system-packages
echo "Done"
