#!/bin/bash
# description: this script is used to build some neceressury files/scripts for init an crd controller
# Copyright 2021 l0calh0st
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#      https://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# PROJECT_NAME is directory of project
PROJECT_NAME=$1
PROJECT_VERSION=$2
PROJECT_AUTHOR=$3

GIT_DOMAIN="github.com"


# exampleoperator.l0calh0st.cn
GROUP_NAME=$(echo ${PROJECT_NAME}|sed 's/-//'|sed 's/_//').${PROJECT_AUTHOR}.cn
# exampleoperator
GROUP_PACKAGE_NAME=$(echo ${PROJECT_NAME}|sed 's/-//'|sed 's/_//')

# CRD type
CRKind=$(echo $(echo ${PROJECT_NAME}|awk -F'-' '{print $1}'|awk -F'_' '{print $1}')|awk '{print toupper(substr($0,1,1))substr($0,2)}')

if [ "${PROJECT_VERSION}" = "" ]
then
    PROJECT_VERSION="v1alpha1"
fi

if [ "${PROJECT_AUTHOR}" = "" ]
then
    PROJECT_AUTHOR="l0calh0st"
fi

function fn_word_all_to_upper()
{
    echo $(echo $1|tr '[:lower:]' '[:upper:]')
}

function fn_word_all_to_lower()
{
    echo $(echo $1|tr '[:upper:]' '[:lower:]')
}

function fn_project_module()
{
    echo "${GIT_DOMAIN}/${PROJECT_AUTHOR}/${PROJECT_NAME}"
}

# create project directory
mkdir -pv ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/${PROJECT_VERSION}
mkdir -pv ${PROJECT_NAME}/pkg/client



##############################################################################
#                         GENGROUPS SECTION                                  #
##############################################################################


# auto generate regisgter.go file
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/register.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package ${GROUP_PACKAGE_NAME}

const (
	GroupName = "${GROUP_NAME}"
)
EOF

# auto generate doc.go
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/${PROJECT_VERSION}/doc.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// +k8s:deepcopy-gen=package
// +groupName=${GROUP_NAME}

// Package ${PROJECT_VERSION} is the ${PROJECT_VERSION} version of the API.
package ${PROJECT_VERSION} // import "$(fn_project_module)/pkg/apis/${GROUP_NAME}/${PROJECT_VERSION}"


EOF

# auto geneate types.go
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/${PROJECT_VERSION}/types.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


package ${PROJECT_VERSION}

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)


// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +k8s:defaulter-gen=true

// ${CRKind} defines ${CRKind} deployment
type ${CRKind} struct {
	metav1.TypeMeta \`json:",inline"\`
	metav1.ObjectMeta \`json:"metadata,omitempty"\`

	Spec ${CRKind}Spec \`json:"spec"\`
	Status ${CRKind}Status \`json:"status"\`
}


// ${CRKind}Spec describes the specification of ${CRKind} applications using kubernetes as a cluster manager
type ${CRKind}Spec struct {
    // todo, write your code
}

// ${CRKind}Status describes the current status of ${CRKind} applications
type ${CRKind}Status struct {
    // todo, write your code
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// ${CRKind}List carries a list of ${CRKind} objects
type ${CRKind}List struct {
	metav1.TypeMeta \`json:",inline"\`
	metav1.ListMeta \`json:"metadata,omitempty"\`

	Items []$CRKind \`json:"items"\`
}
EOF

# generate regiser.go
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/${PROJECT_VERSION}/register.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package ${PROJECT_VERSION}

import (
    "$(fn_project_module)/pkg/apis/${GROUP_NAME}"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

const (
    Version = "${PROJECT_VERSION}"
)

var (
    // SchemeBuilder initializes a scheme builder
	SchemeBuilder = runtime.NewSchemeBuilder(addKnowTypes)
    // AddToScheme is a global function that registers this API group & version to a scheme
	AddToScheme = SchemeBuilder.AddToScheme
)

var (
    // SchemeGroupPROJECT_VERSION is group version used to register these objects
	SchemeGroupVersion = schema.GroupVersion{Group:  ${GROUP_PACKAGE_NAME}.GroupName, Version: Version}
)

// Resource takes an unqualified resource and returns a Group-qualified GroupResource.
func Resource(resource string)schema.GroupResource{
	return SchemeGroupVersion.WithResource(resource).GroupResource()
}

// Kind takes an unqualified kind and returns back a Group qualified GroupKind
func Kind(kind string)schema.GroupKind{
	return SchemeGroupVersion.WithKind(kind).GroupKind()
}

// addKnownTypes adds the set of types defined in this package to the supplied scheme.
func addKnowTypes(scheme *runtime.Scheme)error{
	scheme.AddKnownTypes(SchemeGroupVersion,
		new(${CRKind}),
        new(${CRKind}List),)
	metav1.AddToGroupVersion(scheme, SchemeGroupVersion)
	return nil
}
EOF


##############################################################################
#                         CMD       SECTION                                  #
##############################################################################
# generate some helper code
mkdir -pv ${PROJECT_NAME}/cmd/operator/options

# generate main code
cat >> ${PROJECT_NAME}/cmd/operator/main.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"flag"
	"k8s.io/component-base/logs"
)

func main() {
	logs.InitLogs()
	defer logs.FlushLogs()

	cmd := NewStartCommand(SetupSignalHandler())
	cmd.Flags().AddGoFlagSet(flag.CommandLine)
	if err := cmd.Execute();err != nil{
		panic(err)
	}
}

EOF

cat >> ${PROJECT_NAME}/cmd/operator/signals.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"os"
	"os/signal"
	"syscall"
)

var (
	onlyOneSignalHandler = make(chan struct{})
	shutdownSignals      = []os.Signal{os.Interrupt, syscall.SIGTERM}
)

// SetupSignalHandler registered for SIGTERM and SIGINT. A stop channel is returned
// which is closed on one of these signals. If a second signal is caught, the program
// is terminated with exit code 1.
func SetupSignalHandler() (stopCh <-chan struct{}) {
	close(onlyOneSignalHandler) // panics when called twice

	stop := make(chan struct{})
	c := make(chan os.Signal, 2)
	signal.Notify(c, shutdownSignals...)
	go func() {
		<-c
		close(stop)
		<-c
		os.Exit(1) // second signal. Exit directly.
	}()

	return stop
}

EOF

cat >> ${PROJECT_NAME}/cmd/operator/start.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"context"
	"flag"
	"fmt"
    "$(fn_project_module)/cmd/operator/options"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/spf13/cobra"
	"golang.org/x/sync/errgroup"
	cliflag "k8s.io/component-base/cli/flag"
	"k8s.io/component-base/term"
	"k8s.io/klog/v2"
	"net"
	"net/http"
	"os"
)

func NewStartCommand(stopCh <-chan struct{}) *cobra.Command {
	opts := options.NewOptions()
	cmd := &cobra.Command{
		Short: "Launch ${PROJECT_NAME}",
		Long:  "Launch ${PROJECT_NAME}",
		RunE: func(cmd *cobra.Command, args []string) error {
			if err := opts.Validate(); err != nil {
				return fmt.Errorf("Options validate failed, %v. ", err)
			}
			if err := opts.Complete(); err != nil {
				return fmt.Errorf("Options Complete failed %v. ", err)
			}
			if err := runCommand(opts, stopCh); err != nil {
				return fmt.Errorf("Run %s failed. ", os.Args[0])
			}
			return nil
		},
	}
	fs := cmd.Flags()
	nfs := opts.NamedFlagSets()
	for _, f := range nfs.FlagSets {
		fs.AddFlagSet(f)
	}
	local := flag.NewFlagSet(os.Args[0], flag.ExitOnError)
	klog.InitFlags(local)
	nfs.FlagSet("logging").AddGoFlagSet(local)

	usageFmt := "Usage:\n %s\n"
	cols, _, _ := term.TerminalSize(cmd.OutOrStdout())
	cmd.SetUsageFunc(func(command *cobra.Command) error {
		fmt.Fprintf(cmd.OutOrStderr(), usageFmt, cmd.UseLine())
		cliflag.PrintSections(cmd.OutOrStderr(), nfs, cols)
		return nil
	})
	cmd.SetHelpFunc(func(command *cobra.Command, strings []string) {
		fmt.Fprintf(cmd.OutOrStdout(), "%s\n\n"+usageFmt, cmd.Long, cmd.UseLine())
		cliflag.PrintSections(cmd.OutOrStdout(), nfs, cols)
	})
	return cmd
}

func runCommand(o *options.Options, stopCh <-chan struct{}) error {
	ctx, cancel := context.WithCancel(context.Background())
	wg, ctx := errgroup.WithContext(ctx)
	defer cancel()
	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.HandlerFor(nil, promhttp.HandlerOpts{}))
	svc := &http.Server{Handler: mux}
	l, err := net.Listen("tcp", o.ListenAddress)
	if err != nil {
		panic(err)
	}
	wg.Go(serve(svc, l))
    // todo write your code here
	if err = wg.Wait(); err != nil {
		return err
	}
	return nil
}

func serve(srv *http.Server, listener net.Listener) func() error {
	return func() error {
		//level.Info(logger).Log("msg", "Starting insecure server on "+listener.Addr().String())
		if err := srv.Serve(listener); err != http.ErrServerClosed {
			return err
		}
		return nil
	}
}

func serveTLS(srv *http.Server, listener net.Listener) func() error {
	return func() error {
		//level.Info(logger).Log("msg", "Starting secure server on "+listener.Addr().String())
		if err := srv.ServeTLS(listener, "", ""); err != http.ErrServerClosed {
			return err
		}
		return nil
	}
}

EOF

cat >> ${PROJECT_NAME}/cmd/operator/options/interface.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package options

import "github.com/spf13/pflag"

// all custom options should implement this interfaces
type options interface {
	Validate()[]error
	Complete()error
	AddFlags(*pflag.FlagSet)
}
EOF

cat >> ${PROJECT_NAME}/cmd/operator/options/options.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


package options

import (
	"github.com/spf13/pflag"
	"k8s.io/component-base/cli/flag"
)

type Options struct {
    // this is example flags
	ListenAddress string
    // todo write your flags here
}

var _ options = new(Options)

// NewOptions create an instance option and return
func NewOptions()*Options{
    // todo write your code or change this code here
	return &Options{}
}


// Validate validates options
func(o *Options)Validate()[]error{
    // todo write your code here, if you need some validation
	return nil
}

// Complete fill some default value to options
func(o *Options)Complete()error{
    // todo write your code here, you may do some defaulter if neceressary
	return nil
}

//
func(o *Options)AddFlags(fs *pflag.FlagSet){
	fs.String("web.listen-addr", ":8080", "Address on which to expose metrics and web interfaces")
    // todo write your code here
}


func(o *Options)NamedFlagSets()(fs flag.NamedFlagSets){
	o.AddFlags(fs.FlagSet("loki-operator"))
	// other options addFlags
	return
}

EOF

##############################################################################
#                       CONTROLLER  SECTION                                  #
##############################################################################

mkdir -pv ${PROJECT_NAME}/pkg/controller

# CONTROLLER_BASE
cat >> ${PROJECT_NAME}/pkg/controller/base.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controller

import "errors"

type Base struct {
	hooks []Hook
}

func NewControllerBase()Base{
	return Base{hooks: []Hook{}}
}

func(c *Base)GetHooks()[]Hook{
	return c.hooks
}

func (c *Base) AddHook(hook Hook) error {
	for _,h := range c.hooks{
		if h == hook{
			return errors.New("Given hook is already installed in the current controller ")
		}
	}
	c.hooks = append(c.hooks)
	return nil
}

func (c *Base) RemoveHook(hook Hook) error {
	for i,h := range c.hooks{
		if h == hook{
			c.hooks = append(c.hooks[:i], c.hooks[i+1:]...)
			return nil
		}
	}
	return errors.New("Given hook is not installed in the current controller ")
}
EOF

# CONTROLLER_EVENT
cat >> ${PROJECT_NAME}/pkg/controller/event.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


package controller

// EventType represents the type of a Event
type EventType int

// All Available Event type
const (
	EventAdded EventType = iota + 1
	EventUpdated
	EventDeleted
)

// Event represent event processed by controller.
type Event struct {
	Type   EventType
	Object interface{}
}

// EventsHook extends \`Hook\` interface.
type EventsHook interface {
	Hook
	GetEventsChan() <-chan Event
}

type eventsHooks struct {
	events chan Event
}

func (e *eventsHooks) OnAdd(object interface{}) {
	e.events <- Event{
		Type:   EventAdded,
		Object: object,
	}
}

func (e *eventsHooks) OnUpdate(object interface{}) {
	e.events <- Event{
		Type:   EventUpdated,
		Object: object,
	}
}

func (e *eventsHooks) OnDelete(object interface{}) {
	e.events <- Event{
		Type:   EventDeleted,
		Object: object,
	}
}

func (e *eventsHooks) GetEventsChan() <-chan Event {
	return e.events
}

func NewEventsHook(channelSize int) EventsHook {
	return &eventsHooks{events: make(chan Event, channelSize)}
}
EOF

# CONTROLLER_HOOK
cat >> ${PROJECT_NAME}/pkg/controller/hook.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controller

// Hook is interface for hooks that can be inject into custom controller
type Hook interface {
	// OnAdd runs after the controller finished processing the addObject
	OnAdd(object interface{})
	// OnUpdate runs after the controller finished processing the updatedObject
	OnUpdate(object interface{})
	// OnDelete run after the controller finished processing the deletedObject
	OnDelete(object interface{})
}


EOF

# CONTROLLER_DOC
cat >> ${PROJECT_NAME}/pkg/controller/doc.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controller

// all code in controller package is automatic-generate, you shouldn't write code in this package if you know what are doing
// all business code should be written in operator package

// 所有controller相关的代码都自动生成的，你不应该修改这个里面的代码(除非你知道你需要做什么).
// 所有业务相关的代码应该在operator里面

EOF

# CONTROLLER_CRKIND
mkdir -pv ${PROJECT_NAME}/pkg/controller/$(fn_word_all_to_lower ${CRKind})
cat >> ${PROJECT_NAME}/pkg/controller/$(fn_word_all_to_lower ${CRKind})/controller.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package $(fn_word_all_to_lower ${CRKind})
EOF

cat >> ${PROJECT_NAME}/pkg/controller/$(fn_word_all_to_lower ${CRKind})/collector.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package $(fn_word_all_to_lower ${CRKind})
EOF

cat >> ${PROJECT_NAME}/pkg/controller/$(fn_word_all_to_lower ${CRKind})/handler.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package $(fn_word_all_to_lower ${CRKind})
EOF

cat >> ${PROJECT_NAME}/pkg/controller/$(fn_word_all_to_lower ${CRKind})/informer.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package $(fn_word_all_to_lower ${CRKind})
EOF
# generate crtype 

##############################################################################
#                       OPERATOR    SECTION                                  #
##############################################################################
mkdir ${PROJECT_NAME}/pkg/operator/
cat >> ${PROJECT_NAME}/pkg/operator/operator.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package operator

// Operator implement reconcile interface, all operator should implement this interface
type Operator interface {
	Reconcile(obj interface{})error
}


EOF

cat >> ${PROJECT_NAME}/pkg/operator/doc.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package operator

// all business code write in this package
// all relative operator should implement \`Operator\` interface

// 所有的业务代码应该写在这个package里面
// 所有相关的operator都应该实现\`Operator\`代码

EOF

mkdir -pv  ${PROJECT_NAME}/pkg/operator/$(fn_word_all_to_lower ${CRKind})
cat >> ${PROJECT_NAME}/pkg/operator/$(fn_word_all_to_lower ${CRKind})/operator.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, PROJECT_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package $(fn_word_all_to_lower ${CRKind})

EOF


##############################################################################
#                       HACKER      SECTION                                  #
##############################################################################


# generate hackscripts
mkdir -pv ${PROJECT_NAME}/hack
mkdir -pv ${PROJECT_NAME}/hack/docker ${PROJECT_NAME}/hack/scripts
# create kubernetes builder images
GOVERSION=$(go env GOVERSION)
cat >> ${PROJECT_NAME}/hack/docker/codegen.dockerfile << EOF
FROM golang:${GOVERSION//go/}

ENV GO111MODULE=auto
ENV GOPROXY="https://goproxy.cn"

RUN go get k8s.io/code-generator; exit 0
WORKDIR /go/src/k8s.io/code-generator
RUN go get -d ./...

RUN mkdir -p /go/src/$(fn_project_module)
VOLUME /go/src/$(fn_project_module)

WORKDIR /go/src/$(fn_project_module)
EOF


cat >> ${PROJECT_NAME}/hack/tools.go << EOF
// +build tools

package tools

import _ "k8s.io/code-generator"
EOF


cat >> ${PROJECT_NAME}/hack/scripts/codegen-update.sh << EOF
#!/usr/bin/env bash

CURRENT_DIR=\$(echo "\$(pwd)/\$line")
REPO_DIR="\$CURRENT_DIR"
IMAGE_NAME="kubernetes-codegen:latest"

echo "Building codgen Docker image ...."
docker build -f "\${CURRENT_DIR}/hack/docker/codegen.dockerfile" \\
             -t "\${IMAGE_NAME}" \\
             "\${REPO_DIR}" 
            

cmd="go mod tidy && /go/src/k8s.io/code-generator/generate-groups.sh  all  \\
        "$(fn_project_module)/pkg/client" \\
        "$(fn_project_module)/pkg/apis" \\
        ${GROUP_NAME}:${PROJECT_VERSION} -h /go/src/k8s.io/code-generator/hack/boilerplate.go.txt"
    
echo "Generating client codes ...."

docker run --rm -v "\${REPO_DIR}:/go/src/$(fn_project_module)" \\
        "\${IMAGE_NAME}" /bin/bash -c "\${cmd}"
EOF


# mkdir e2e test package
mkdir -pv ${PROJECT_NAME}/e2e

# init go mod
cd ${PROJECT_NAME} && go mod init $(fn_project_module)  

# execute upgroup.sh
bash hack/scripts/codegen-update.sh

# vendor
go mod tidy && go mod vendor
# do 
