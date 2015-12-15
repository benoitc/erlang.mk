# Dialyzer plugin.

DIALYZER_CASES = app apps-only apps-with-local-deps check custom-plt deps erlc-opts local-deps opts plt-apps
DIALYZER_TARGETS = $(addprefix dialyzer-,$(DIALYZER_CASES))
DIALYZER_CLEAN_TARGETS = $(addprefix clean-,$(DIALYZER_TARGETS))

.PHONY: dialyzer $(C_SRC_TARGETS) clean-dialyzer $(DIALYZER_CLEAN_TARGETS)

clean-dialyzer: $(DIALYZER_CLEAN_TARGETS)

$(DIALYZER_CLEAN_TARGETS):
	$t rm -rf $(APP_TO_CLEAN)

dialyzer: $(DIALYZER_TARGETS)

dialyzer-app: build clean-dialyzer-app

	$i "Bootstrap a new OTP application named $(APP)"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t $(MAKE) -C $(APP) -f erlang.mk bootstrap $v

	$i "Run Dialyzer"
	$t $(MAKE) -C $(APP) dialyze $v

	$i "Check that the PLT file was created"
	$t test -f $(APP)/.$(APP).plt

	$i "Create a module with a function that has no local return"
	$t printf "%s\n" \
		"-module(warn_me)." \
		"doit() -> 1 = 2, ok." > $(APP)/src/warn_me.erl

	$i "Confirm that Dialyzer errors out"
	$t ! $(MAKE) -C $(APP) dialyze $v

	$i "Distclean the application"
	$t $(MAKE) -C $(APP) distclean $v

	$i "Check that the PLT file was removed"
	$t test ! -e $(APP)/.$(APP).plt

dialyzer-apps-only: build clean-dialyzer-apps-only

	$i "Create a multi application repository with no root application"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t echo "include erlang.mk" > $(APP)/Makefile

	$i "Create a new application my_app"
	$t $(MAKE) -C $(APP) new-app in=my_app $v

	$i "Create a module my_server from gen_server template in my_app"
	$t $(MAKE) -C $(APP) new t=gen_server n=my_server in=my_app $v

	$i "Add Cowlib to the list of dependencies"
	$t perl -ni.bak -e 'print;if ($$.==1) {print "DEPS = cowlib\n"}' $(APP)/apps/my_app/Makefile

	$i "Run Dialyzer"
	$t $(MAKE) -C $(APP) dialyze $v

	$i "Check that the PLT file was created automatically"
	$t test -f $(APP)/.$(APP).plt

	$i "Confirm that Cowlib was included in the PLT"
	$t dialyzer --plt_info --plt $(APP)/.$(APP).plt | grep -q cowlib

	$i "Create a module with a function that has no local return"
	$t printf "%s\n" \
		"-module(warn_me)." \
		"doit() -> 1 = 2, ok." > $(APP)/apps/my_app/src/warn_me.erl

	$i "Confirm that Dialyzer errors out"
	$t ! $(MAKE) -C $(APP) dialyze $v

dialyzer-apps-with-local-deps: build clean-dialyzer-apps-with-local-deps

	$i "Create a multi application repository with no root application"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t echo "include erlang.mk" > $(APP)/Makefile

	$i "Create a new application my_app"
	$t $(MAKE) -C $(APP) new-app in=my_app $v

	$i "Create a new application my_core_app"
	$t $(MAKE) -C $(APP) new-app in=my_core_app $v

	$i "Add my_core_app to the list of local dependencies for my_app"
	$t perl -ni.bak -e 'print;if ($$.==1) {print "LOCAL_DEPS = my_core_app\n"}' $(APP)/apps/my_app/Makefile

	$i "Run Dialyzer"
	$t $(MAKE) -C $(APP) dialyze $v

	$i "Check that the PLT file was created automatically"
	$t test -f $(APP)/.$(APP).plt

	$i "Confirm that my_core_app was NOT included in the PLT"
	$t ! dialyzer --plt_info --plt $(APP)/.$(APP).plt | grep -q my_core_app

dialyzer-check: build clean-dialyzer-check

	$i "Bootstrap a new OTP application named $(APP)"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t $(MAKE) -C $(APP) -f erlang.mk bootstrap $v

	$i "Run 'make check'"
	$t $(MAKE) -C $(APP) check $v

	$i "Check that the PLT file was created"
	$t test -f $(APP)/.$(APP).plt

	$i "Create a module with a function that has no local return"
	$t printf "%s\n" \
		"-module(warn_me)." \
		"doit() -> 1 = 2, ok." > $(APP)/src/warn_me.erl

	$i "Confirm that Dialyzer errors out on 'make check'"
	$t ! $(MAKE) -C $(APP) check $v

dialyzer-custom-plt: build clean-dialyzer-custom-plt

	$i "Bootstrap a new OTP application named $(APP)"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t $(MAKE) -C $(APP) -f erlang.mk bootstrap $v

	$i "Set a custom DIALYZER_PLT location"
	$t perl -ni.bak -e 'print;if ($$.==1) {print "DIALYZER_PLT = custom.plt\n"}' $(APP)/Makefile

	$i "Run Dialyzer"
	$t $(MAKE) -C $(APP) dialyze $v

	$i "Check that the PLT file was created"
	$t test -f $(APP)/custom.plt

	$i "Distclean the application"
	$t $(MAKE) -C $(APP) distclean $v

	$i "Check that the PLT file was removed"
	$t test ! -e $(APP)/custom.plt

dialyzer-deps: build clean-dialyzer-deps

	$i "Bootstrap a new OTP application named $(APP)"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t $(MAKE) -C $(APP) -f erlang.mk bootstrap $v

	$i "Add Cowlib to the list of dependencies"
	$t perl -ni.bak -e 'print;if ($$.==1) {print "DEPS = cowlib\n"}' $(APP)/Makefile

	$i "Run Dialyzer"
	$t $(MAKE) -C $(APP) dialyze $v

	$i "Check that the PLT file was created"
	$t test -f $(APP)/.$(APP).plt

	$i "Confirm that Cowlib was included in the PLT"
	$t dialyzer --plt_info --plt $(APP)/.$(APP).plt | grep -q cowlib

dialyzer-erlc-opts: build clean-dialyzer-erlc-opts

	$i "Bootstrap a new OTP application named $(APP)"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t $(MAKE) -C $(APP) -f erlang.mk bootstrap $v

	$i "Create a header file in a non-standard directory"
	$t mkdir $(APP)/exotic/
	$t touch $(APP)/exotic/dialyze.hrl

	$i "Create a module that includes this header"
	$t printf "%s\n" \
		"-module(no_warn)." \
		"-export([doit/0])." \
		"-include(\"dialyze.hrl\")." \
		"doit() -> ok." > $(APP)/src/no_warn.erl

	$i "Point ERLC_OPTS to the non-standard include directory"
	$t perl -ni.bak -e 'print;if ($$.==1) {print "ERLC_OPTS += -I exotic\n"}' $(APP)/Makefile

	$i "Run Dialyzer"
	$t $(MAKE) -C $(APP) dialyze $v

dialyzer-local-deps: build clean-dialyzer-local-deps

	$i "Bootstrap a new OTP application named $(APP)"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t $(MAKE) -C $(APP) -f erlang.mk bootstrap $v

	$i "Add runtime_tools to the list of local dependencies"
	$t perl -ni.bak -e 'print;if ($$.==1) {print "LOCAL_DEPS = runtime_tools\n"}' $(APP)/Makefile

	$i "Build the PLT"
	$t $(MAKE) -C $(APP) plt $v

	$i "Confirm that runtime_tools was included in the PLT"
	$t dialyzer --plt_info --plt $(APP)/.$(APP).plt | grep -q runtime_tools

dialyzer-opts: build clean-dialyzer-opts

	$i "Bootstrap a new OTP application named $(APP)"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t $(MAKE) -C $(APP) -f erlang.mk bootstrap $v

	$i "Make Dialyzer save output to a file"
	$t perl -ni.bak -e 'print;if ($$.==1) {print "DIALYZER_OPTS = -o output.txt\n"}' $(APP)/Makefile

	$i "Create a module with a function that has no local return"
	$t printf "%s\n" \
		"-module(warn_me)." \
		"-export([doit/0])." \
		"doit() -> gen_tcp:connect(a, b, c), ok." > $(APP)/src/warn_me.erl

	$i "Run Dialyzer"
	$t ! $(MAKE) -C $(APP) dialyze $v

	$i "Check that the PLT file was created"
	$t test -f $(APP)/.$(APP).plt

	$i "Check that the output file was created"
	$t test -f $(APP)/output.txt

dialyzer-plt-apps: build clean-dialyzer-plt-apps

	$i "Bootstrap a new OTP application named $(APP)"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t $(MAKE) -C $(APP) -f erlang.mk bootstrap $v

	$i "Add runtime_tools to PLT_APPS"
	$t perl -ni.bak -e 'print;if ($$.==1) {print "PLT_APPS = runtime_tools\n"}' $(APP)/Makefile

	$i "Build the PLT"
	$t $(MAKE) -C $(APP) plt $v

	$i "Confirm that runtime_tools was included in the PLT"
	$t dialyzer --plt_info --plt $(APP)/.$(APP).plt | grep -q runtime_tools