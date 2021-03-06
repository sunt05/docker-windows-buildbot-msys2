# escape=`

ARG BASE_TAG=windowsservercore-ltsc2016

FROM python:${BASE_TAG}

SHELL ["powershell", "-command"]

RUN Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

RUN choco install python3 --version 3.6.5 -y

ARG GIT_X64="https://github.com/git-for-windows/git/releases/download/v2.18.0.windows.1/Git-2.18.0-64-bit.exe"
ADD ${GIT_X64} C:\Windows\Temp\Git-64-bit.exe

RUN Start-Process -FilePath "C:\Windows\Temp\Git-64-bit.exe" -ArgumentList /VERYSILENT, /NORESTART, /NOCANCEL, /SP- -NoNewWindow -PassThru -Wait; `
    Remove-Item @('C:\Windows\Temp\*', 'C:\Users\*\Appdata\Local\Temp\*') -Force -Recurse;

ARG P7Z_X64="http://www.7-zip.org/a/7z1604-x64.exe"
ADD ${P7Z_X64} C:\Windows\Temp\7z1604-x64.exe

RUN Start-Process -FilePath "C:\Windows\Temp\7z1604-x64.exe" -ArgumentList /S -NoNewWindow -PassThru -Wait; `
    Remove-Item @('C:\Windows\Temp\*', 'C:\Users\*\Appdata\Local\Temp\*') -Force -Recurse;

ARG MSYS2_X86_64="http://repo.msys2.org/distrib/msys2-x86_64-latest.tar.xz"
ADD ${MSYS2_X86_64} C:\Windows\Temp\msys2-x86_64-latest.tar.xz

RUN Start-Process -FilePath "C:\Program` Files\7-Zip\7z.exe" -ArgumentList e, "C:\Windows\Temp\msys2-x86_64-latest.tar.xz", `-oC:\Windows\Temp\ -NoNewWindow -PassThru -Wait; `
    Start-Process -FilePath "C:\Program` Files\7-Zip\7z.exe" -ArgumentList x, "C:\Windows\Temp\msys2-x86_64-latest.tar", `-oC:\ -NoNewWindow -PassThru -Wait; `
    Remove-Item @('C:\Windows\Temp\*', 'C:\Users\*\Appdata\Local\Temp\*') -Force -Recurse;

RUN Write-Host 'Updating MSYSTEM and MSYSCON ...'; `
    [Environment]::SetEnvironmentVariable('MSYSTEM', 'MSYS2', [EnvironmentVariableTarget]::Machine); `
    [Environment]::SetEnvironmentVariable('MSYSCON', 'defterm', [EnvironmentVariableTarget]::Machine);

# For some reason bash.exe has to be called first since we are not building interactive.
RUN C:\msys64\usr\bin\bash.exe -l -c 'exit 0'; `
    C:\msys64\usr\bin\bash.exe -l -c 'echo "Now installing MSYS2..."'; `
    C:\msys64\usr\bin\bash.exe -l -c 'pacman -Syuu --needed --noconfirm --noprogressbar --ask=20'; `
    C:\msys64\usr\bin\bash.exe -l -c 'pacman -Syu  --needed --noconfirm --noprogressbar --ask=20'; `
    C:\msys64\usr\bin\bash.exe -l -c 'pacman -Su   --needed --noconfirm --noprogressbar --ask=20'; `
    C:\msys64\usr\bin\bash.exe -l -c 'echo "Successfully installed MSYS2"';

RUN C:\msys64\usr\bin\bash.exe -l -c 'exit 0'; `
    C:\msys64\usr\bin\bash.exe -l -c 'echo "Now installing MinGW-w64..."'; `
    C:\msys64\usr\bin\bash.exe -l -c 'pacman -S --needed --noconfirm --noprogressbar mingw-w64-i686-toolchain mingw-w64-x86_64-toolchain'; `
    C:\msys64\usr\bin\bash.exe -l -c 'pacman -S --needed --noconfirm --noprogressbar automake autoconf make intltool libtool zip unzip'; `
    C:\msys64\usr\bin\bash.exe -l -c 'echo "Successfully installed MinGW-w64"';


# set make as visible from mingw-make
RUN Copy-Item -Path C:\msys64\mingw64\bin\mingw32-make.exe -Destination C:\msys64\mingw64\bin\make.exe

# set path for MinGW64 bin
RUN $path = $env:path + ';c:\msys64\mingw64\bin'; Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\' -Name Path -Value $path

CMD ["powershell"]

