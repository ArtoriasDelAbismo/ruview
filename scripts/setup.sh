
#!/bin/bash
echo "Cloning RuView..."
git clone https://github.com/ruvnet/RuView.git ruview
echo "Installing dependencies..."
pip3 install -r ruview/requirements.txt --break-system-packages
echo "Done"
