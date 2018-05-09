@echo off
mkdir .\build\packaging > nul 2>&1
mkdir .\build\packaging\msi > nul 2>&1
makecab /F build\packaging\msi\cab.ddf /L build\packaging\msi