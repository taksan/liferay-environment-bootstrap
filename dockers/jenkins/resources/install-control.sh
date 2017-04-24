cd $(dirname $(readlink -f $0))

function generateInstructions()
{
    cat <<EOF
    <div id="__instructions_div__" style="z-index: 1000;
                position:absolute; 
                left: 0px; 
                top: 0px; 
                background-color: black; 
                width: 300px; 
                min-height: 150px; 
                color: white; font-family: 
                courier; 
                font-size: 14px; 
                padding: 5px; 
                margin: 10px;
                border-radius: 5px;
                border: 1px solid grey;
                box-shadow: 10px 10px 5px #888888;
                ">
            <h3> Instructions </h3>
            $INSTRUCTIONS
    </div>
    <script type='text/javascript'>
        $JS
    </script>
EOF
    exit 0
}

function match()
{
    grep -q "$@" $OUT
}

if [[ $SCRIPT_NAME = "/waitJenkinsReady" ]]; then
    INSTRUCTIONS="Waiting jenkins restart..."
    JS="setTimeout(function() { document.location='/waitJenkinsReady'; }, 200)"
    exit 0
fi

if [[ $SCRIPT_NAME = "/" ]]; then
    if [[ -e /var/www/html/adminUserExists ]]; then
        echo "<h1> Refresh until jenkins comes back</h1>"
        exit 0
    fi
fi

OUT=/tmp/current_content

cat - | tee $OUT

if [[ ! $REQUEST_METHOD = "GET" ]]; then
    exit 0
fi

if match BOOTSTRAP_SETUP; then
    if [[ $SCRIPT_NAME =~ .*.job.BOOTSTRAP_SETUP.build ]]; then
        INSTRUCTIONS="Fill the required information and click 'Build'. Jenkins will restart when configuration finishes."
        JS="document.querySelector('.settings-input').focus()"
    elif [[ $SCRIPT_NAME =~ .*.job.BOOTSTRAP_SETUP ]]; then
        INSTRUCTIONS="Waiting configuration."
    else
        JS="document.location='/job/BOOTSTRAP_SETUP/build'"
    fi
    generateInstructions
fi

if [[ $SCRIPT_NAME = "/down.html" ]] || match "Please wait while Jenkins is getting ready to work"; then
    INSTRUCTIONS="Wait until jenkins becomes available..."
    JS="setInterval(function() { document.location.reload(true)}, 500)"
    generateInstructions
fi



if match "/var/lib/jenkins/secrets/initialAdminPassword"; then
    JS="document.getElementById('security-token').value='$(cat initialAdminPassword)'"
    INSTRUCTIONS="Click the <b>continue</b> button. If the password is not filled, copy and paste this: <p><center>$(cat initialAdminPassword)</center></p>"
    generateInstructions
fi

if match "plugin-setup-wizard-container"; then
    INSTRUCTIONS="Choose 'Install Suggested plugins' and wait until installation is complete."
    JS="
    var once=false;
    new MutationObserver(function (mutationRecord, observer) {
        if (document.querySelector('.installing-panel')) {
            if (!once) return;
            once = true;
            document.getElementById('__instructions_div__').innerHTML='Installing plugins... please wait';
            return;
        }
        if (!document.querySelector('.skip-first-user'))
            return;

        observer.disconnect();
        document.getElementById('__instructions_div__').innerHTML='Fill out admin information and click <b>Save and Finish</b>. After click, refresh a couple times until you get to the login page.'

        // prevent user from choosing to skip configuration option
        document.querySelector('.skip-first-user').style.display='none'
        document.querySelector('.save-first-user').addEventListener('click', function() {
            setTimeout(function() { document.location.reload(true); }, 100)
        });
    }).observe(document, {subtree: true, childList: true});
"    
    generateInstructions
fi

if [[ $SCRIPT_NAME = /login ]] && match "User:"; then
    INSTRUCTIONS="Login to proceed"
    generateInstructions
    exit 0
fi

if [[ -e admin-user-setup-done ]]; then
    INSTRUCTIONS="Wait for restart"
    generateInstructions
    exit 0
fi
