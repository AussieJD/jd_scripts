#!/bin/sh
#
# StarOffice patch checking script
# (c) 2000, Sun Microsystems Inc.

# Build an executable file that can be run in a separate window.
#

tempfile="/tmp/sopatch.$$"

/bin/cat > $tempfile << EOI
#!/bin/sh
clear
echo ""
sd_platform=\`uname -s\`

if [ "\$sd_platform"="SunOS" ]; then

	echo checking installed system patches ...
	echo ""

	#
	# check required patchid
	#


    sd_hardware=\`uname -p\`
	sd_release=\`uname -r\`
    required_patch=

	case \$sd_hardware in
    i386)
        case \$sd_release in
            5.5.1)
	        required_patch=106530
	        required_minor=05
	        ;;
            5.6)
	        required_patch=104678
	        required_minor=05
	        ;;
            5.7)
	        required_patch=106328
	        required_minor=06
	        ;;
            5.8)
	        required_patch=
	    ;;
        esac
        ;;
    sparc)
        case \$sd_release in
            5.5.1)
	        required_patch=106529
	        required_minor=05
	        ;;
            5.6)
	        required_patch=105591
	        required_minor=06
	        ;;
            5.7)
	        required_patch=106327
	        required_minor=05
	        ;;
            5.8)
	        required_patch=
	        ;;
        esac
    esac

	#
    # if no patch is required we are done
    #


	if [ "\$required_patch" = "" ]; then
		echo ""
		echo "no patches required"
		echo ""
		echo "Move cursor into this window and press Return to exit."
		echo ""

		read userinput
		exit 0
	fi

	#
	# check prerequesites
	#

	if [ ! -x /usr/bin/awk ]; then
		echo ""
		echo "no awk command, check skipped"
		echo ""
		echo "Move cursor into this window and press Return to exit."
		echo ""

		read userinput
		exit 0
	fi

	#
	# check installed patches
	#

    patch_installed=\`/bin/showrev -p | grep SUNWlibC | /usr/bin/awk \\
		'{ \\
			if (\$1 == "Patch:") { \\
				split(\$2, inst_patch, "-"); \\
				if (inst_patch[1] == required_patch) { \\
					if ((inst_patch[2]+1) >= (1+required_minor)){ \\
						print "done"; exit 0; \\
					} \\
				} \\
		 	} \\
			if (\$3 == "Obsoletes:") { \\
				split(\$4, inst_patch, "-"); \\
				if (inst_patch[1] == required_patch) { \\
					if ((inst_patch[2]+1) >= (1+required_minor)){ \\
						print "done"; exit 0; \\
					} \\
				} \\
		 	} \\
		}' required_patch=\$required_patch required_minor=\$required_minor \`

	if [ "\$patch_installed" = "done" ]; then
		echo "required patch installed"
	else
		echo "Please install the patch 'Shared library patch for C++ (Version 5)',
	\${required_patch}-\${required_minor}, or later,
or contact your system administrator"
	fi
fi

echo ""
echo "Move cursor into this window and press Return to exit."
echo ""

read userinput
exit 0
EOI

# Change permissions
chmod +x $tempfile

# Now execute the script
/usr/openwin/bin/shelltool -I "$tempfile; exit"

rm $tempfile
