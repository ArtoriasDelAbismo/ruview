
#!/bin/bash
echo "Cloning RuView..."
git clone https://github.com/ruvnet/RuView.git core
echo "Installing minimal dependencies..."
pip3 install -r requirements-minimal.txt --break-system-packages
echo "Done"
