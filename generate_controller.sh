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

# 所有字符串大写
function fn_strings_to_upper(){
    echo $(echo $1|tr '[:lower:]' '[:upper:]')
}
# 所有字符串小写
function fn_strings_to_lower(){
    echo $(echo $1|tr '[:upper:]' '[:lower:]')
}
# 去除特殊符号
function fn_strings_strip_special_charts(){
  echo $(echo ${1}|sed 's/-//'|sed 's/_//')
}

# 首字母大写
function fn_strings_first_upper(){
    str=$1
    firstLetter=`echo ${str:0:1} | awk '{print toupper($0)}'`
    otherLetter=${str:1}
    result=$firstLetter$otherLetter
    echo $result
}

# 生成 go mod 名称
function fn_project_to_gomod(){

    echo "${GIT_DOMAIN}/${PROJECT_AUTHOR}/${PROJECT_NAME}"
}

function fn_group_name() {
    echo $(echo ${PROJECT_NAME}|sed 's/-//'|sed 's/_//').${PROJECT_AUTHOR}.cn
}




####################################################################################################
#  全局 相关的
####################################################################################################

# auto generate regisgter.go file
# 创建group register.go文件 0x00
function fn_gen_gofile_group_register(){
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    GROUP_NAME=$(fn_strings_to_lower ${2})
    mkdir -pv pkg/apis/${GROUP_NAME}/
    cat >> pkg/apis/${GROUP_NAME}/register.go << EOF
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

    package $(fn_strings_strip_special_charts ${PROJECT_NAME})

    const (
        GroupName = "${GROUP_NAME}"
    )
EOF
    gofmt -w pkg/apis/${GROUP_NAME}/register.go
}

####################################################################################################
#                            资源类型定义
####################################################################################################
# auto generate doc.go
#
function fn_gen_gofile_group_version_doc(){
    PROJECT_NAME=$(fn_strings_to_lower ${1})     # 项目名称
    GROUP_NAME=$(fn_strings_to_lower ${2})       # Group 名称
    GROUP_VERSION=$(fn_strings_to_lower ${3})    # Group 版本
    mkdir pkg/apis/${GROUP_NAME}/${GROUP_VERSION}
    cat >>pkg/apis/${GROUP_NAME}/${GROUP_VERSION}/doc.go << EOF
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

    // Package ${GROUP_VERSION} is the ${GROUP_VERSION} version of the API.
    package ${GROUP_VERSION} // import "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/apis/${GROUP_NAME}/${GROUP_VERSION}"
EOF
    gofmt -w pkg/apis/${GROUP_NAME}/${GROUP_VERSION}/doc.go
}

# auto geneate types.go
function fn_gen_gofile_group_version_types(){
    PROJECT_NAME=$(fn_strings_to_lower ${1})   # 项目名称
    GROUP_NAME=$(fn_strings_to_lower ${2})     # Group 名 称
    GROUP_VERSION=$(fn_strings_to_lower ${3})  # Group 版本
    RESOURCE_KIND=$(fn_strings_to_lower ${4})  # 资源类型
    CRKind=$(fn_strings_first_upper ${RESOURCE_KIND})    #CRKind 名称，首字母要大写
    mkdir pkg/apis/${GROUP_NAME}/${GROUP_VERSION}
    cat >> pkg/apis/${GROUP_NAME}/${GROUP_VERSION}/types.go << EOF
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

    package ${GROUP_VERSION}

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
    gofmt -w pkg/apis/${GROUP_NAME}/${GROUP_VERSION}/types.go
}

# generate regiser.go
function fn_gen_gofile_group_version_register(){
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    GROUP_NAME=$(fn_strings_to_lower ${2})
    GROUP_VERSION=$(fn_strings_to_lower ${3})
    RESOURCE_KIND=$(fn_strings_to_lower ${4})  # 资源类型
    CRKind=$(fn_strings_first_upper ${RESOURCE_KIND})    #CRKind 名称，首字母要大写
    mkdir -pv pkg/apis/${GROUP_NAME}/${GROUP_VERSION}/
    cat >> pkg/apis/${GROUP_NAME}/${GROUP_VERSION}/register.go << EOF
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

    package ${GROUP_VERSION}

    import (
        "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/apis/${GROUP_NAME}"

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
      SchemeGroupVersion = schema.GroupVersion{Group:  $(fn_strings_strip_special_charts ${PROJECT_NAME}).GroupName, Version: Version}
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
    gofmt -w pkg/apis/${GROUP_NAME}/${GROUP_VERSION}/register.go
}
# install
function fn_gen_gofile_install_install(){
      PROJECT_NAME=$(fn_strings_to_lower ${1})     # 项目名称
      GROUP_NAME=$(fn_strings_to_lower ${2})       # Group 名称
      GROUP_VERSION=$(fn_strings_to_lower ${3})    # Group 版本
      mkdir -pv pkg/apis/install
      cat >> pkg/apis/install/install.go << EOF
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
      package install
      import (
      "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/apis/${GROUP_NAME}/${GROUP_VERSION}"
      "k8s.io/apimachinery/pkg/runtime"
      utilruntime "k8s.io/apimachinery/pkg/util/runtime"
       )

    func Install(scheme *runtime.Scheme){
      utilruntime.Must(${GROUP_VERSION}.AddToScheme(scheme))
    }
EOF
    gofmt -w pkg/apis/install/install.go
}


##############################################################################
#                        CMD相关的部分                               #
##############################################################################
# generate some helper code

# generate main code

function fn_gen_gofile_cmd_project_main() {
    PROJECT_NAME=$(fn_strings_to_lower $1)
    mkdir -pv cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/options
    cat >> cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/main.go << EOF
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
    gofmt -w cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))
}

function fn_gen_gofile_cmd_projct_signals() {
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    mkdir -pv cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/
    cat >> cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/signals.go << EOF
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
    gofmt -w cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/signals.go
}

function fn_gen_gofile_cmd_project_startcmd() {
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    GROUP_NAME=$(fn_strings_to_lower ${2})
    GROUP_VERSION=$(fn_strings_to_lower ${3})
    mkdir -pv cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/

    cat >> cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/start.go << EOF
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
      "$(fn_project_to_gomod ${PROJECT_NAME})/cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/options"
      "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/apis/install"
      crclientset "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/client/clientset/versioned"
      "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/client/clientset/versioned/scheme"
      crinformers "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/client/informers/externalversions"
      "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/controller"
      "github.com/prometheus/client_golang/prometheus"
      "github.com/prometheus/client_golang/prometheus/promhttp"
      "github.com/spf13/cobra"
      "golang.org/x/sync/errgroup"
      apicorev1 "k8s.io/api/core/v1"
      v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
      "k8s.io/client-go/informers"
      "k8s.io/client-go/kubernetes"
      "k8s.io/client-go/rest"
      "k8s.io/client-go/tools/clientcmd"
      cliflag "k8s.io/component-base/cli/flag"
      "k8s.io/component-base/term"
      "k8s.io/klog/v2"
      "net"
      "net/http"
      "os"
      "time"
    )

    func NewStartCommand(stopCh <-chan struct{}) *cobra.Command {
      opts := options.NewOptions()
      cmd := &cobra.Command{
        Short: "Launch Loki-Operator",
        Long:  "Launch Loki-Operator",
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

      usageFmt := "Usage:\n  %s\n"
      cols, _, _ := term.TerminalSize(cmd.OutOrStdout())
      cmd.SetUsageFunc(func(cmd *cobra.Command) error {
        _, _ = fmt.Fprintf(cmd.OutOrStderr(), usageFmt, cmd.UseLine())
        cliflag.PrintSections(cmd.OutOrStderr(), nfs, cols)
        return nil
      })
      cmd.SetHelpFunc(func(cmd *cobra.Command, args []string) {
        _, _ = fmt.Fprintf(cmd.OutOrStdout(), "%s\n\n"+usageFmt, cmd.Long, cmd.UseLine())
        cliflag.PrintSections(cmd.OutOrStdout(), nfs, cols)
      })
      return cmd
    }

    func runCommand(o *options.Options, stopCh <-chan struct{}) error {
      var err error
      restConfig, err := buildKubeConfig("", "")
      if err != nil {
        return err
      }
      kubeClientSet, err := kubernetes.NewForConfig(restConfig)
      if err != nil {
        return err
      }
      crClientSet, err := crclientset.NewForConfig(restConfig)
      if err != nil {
        return err
      }
      crInformers := buildCustomResourceInformerFactory(crClientSet)
      kubeInformers := buildKubeStandardResourceInformerFactory(kubeClientSet)
      go crInformers.Start(stopCh)
      go kubeInformers.Start(stopCh)

      register := prometheus.NewRegistry()
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


      install.Install(scheme.Scheme)

      if err = wg.Wait(); err != nil {
        return err
      }
      return nil
    }

    func runController(ctx context.Context, controller controller.Controller) func() error {
      return func() error {
        if err := controller.Start(ctx); err != nil {
          return err
        }
        return nil
      }
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

    // buildKubeConfig build rest.Config from the following ways
    // 1: path of kube_config 2: KUBECONFIG environment 3. ~/.kube/config, as kubeconfig may not in $HOMEDIR/.kube/
    func buildKubeConfig(masterUrl, kubeConfig string) (*rest.Config, error) {
      cfgLoadingRules := clientcmd.NewDefaultClientConfigLoadingRules()
      cfgLoadingRules.DefaultClientConfig = &clientcmd.DefaultClientConfig
      cfgLoadingRules.ExplicitPath = kubeConfig
      clientConfig := clientcmd.NewNonInteractiveDeferredLoadingClientConfig(cfgLoadingRules, &clientcmd.ConfigOverrides{})
      config, err := clientConfig.ClientConfig()
      if err != nil {
        return nil, err
      }
      if err = rest.SetKubernetesDefaults(config); err != nil {
        return nil, err
      }
      return config, nil
    }

    // buildCustomResourceInformerFactory build crd informer factory according some options
    func buildCustomResourceInformerFactory(crClient crclientset.Interface) crinformers.SharedInformerFactory {
      var factoryOpts []crinformers.SharedInformerOption
      factoryOpts = append(factoryOpts, crinformers.WithNamespace(apicorev1.NamespaceAll))
      factoryOpts = append(factoryOpts, crinformers.WithTweakListOptions(func(listOptions *v1.ListOptions) {
        // todo
      }))
      return crinformers.NewSharedInformerFactoryWithOptions(crClient, 5*time.Second, factoryOpts...)
    }

    // buildKubeStandardResourceInformerFactory build a kube informer factory according some options
    func buildKubeStandardResourceInformerFactory(kubeClient kubernetes.Interface) informers.SharedInformerFactory {
      var factoryOpts []informers.SharedInformerOption
      factoryOpts = append(factoryOpts, informers.WithNamespace(apicorev1.NamespaceAll))
      //factoryOpts = append(factoryOpts, informers.WithCustomResyncConfig(nil))
      factoryOpts = append(factoryOpts, informers.WithTweakListOptions(func(listOptions *v1.ListOptions) {
        // todo
      }))
      return informers.NewSharedInformerFactoryWithOptions(kubeClient, 5*time.Second, factoryOpts...)
    }
EOF
    gofmt -w cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/start.go
}

function fn_gen_gofile_cmd_project_options_interface() {
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    # create some relative dirs
    mkdir -pv cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/options/
    # generate interface.go file
    cat >> cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/options/interface.go << EOF
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
    gofmt -w cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/options/interface.go
}

function fn_gen_gofile_cmd_project_options_options(){
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    mkdir -pv cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/options/
    cat >> cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/options/options.go << EOF
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
    gofmt -w cmd/$(fn_strings_to_lower $(fn_strings_strip_special_charts ${PROJECT_NAME}))/options/options.go
}


##############################################################################
#                       Controller相关部分                                 #
##############################################################################

function fn_gen_gofile_pkg_controller_interfaces() {
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    mkdir -pv pkg/controller
    # CONTROLLER_BASE

        cat >> pkg/controller/controller.go << EOF
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
    import "context"

    // Controller is generic interface for custom controller, it defines the basic behaviour of custom controller
    type Controller interface {
      Start(ctx context.Context) error
      Stop()
      AddHook(hook Hook) error
      RemoveHook(hook Hook) error
    }

EOF
    gofmt -w pkg/controller/controller.go

    cat >> pkg/controller/base.go << EOF
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
    gofmt -w pkg/controller/base.go
    # CONTROLLER_EVENT
    cat >> pkg/controller/event.go << EOF
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
    gofmt -w pkg/controller/event.go
    # CONTROLLER_HOOK
    cat >> pkg/controller/hook.go << EOF
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
    gofmt -w pkg/controller/hook.go
    # CONTROLLER_DOC
    cat >> pkg/controller/doc.go << EOF
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
    gofmt -w pkg/controller/doc.go
}

function fn_gen_package_pkg_controller_CRKind() {
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    GROUP_NAME=$(fn_strings_to_lower ${2})
    GROUP_VERSION=$(fn_strings_to_lower ${3})
    CRKind=$(fn_strings_first_upper $(fn_strings_to_lower ${4}))
# CONTROLLER_CRKIND
    mkdir -pv pkg/controller/$(fn_strings_to_lower ${CRKind})
    cat >> pkg/controller/$(fn_strings_to_lower ${CRKind})/controller.go << EOF
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

    package $(fn_strings_to_lower ${CRKind})
        import (
        "context"
        "fmt"
        "time"
        "github.com/prometheus/client_golang/prometheus"
        apicorev1 "k8s.io/api/core/v1"
        utilruntime "k8s.io/apimachinery/pkg/util/runtime"
        "k8s.io/apimachinery/pkg/util/wait"
        "k8s.io/client-go/informers"
        kubeclientset "k8s.io/client-go/kubernetes"
        "k8s.io/client-go/kubernetes/scheme"
        typedcorev1 "k8s.io/client-go/kubernetes/typed/core/v1"
        listercorev1 "k8s.io/client-go/listers/core/v1"
        "k8s.io/client-go/tools/cache"
        "k8s.io/client-go/tools/record"
        "k8s.io/client-go/util/workqueue"
        "k8s.io/klog/v2"

        crclientset "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/client/clientset/versioned"
        crinformers "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/client/informers/externalversions"
        crlisterv1alpha1 "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/client/listers/$(fn_strings_to_lower ${GROUP_NAME})/$(fn_strings_to_lower ${GROUP_VERSION})"
        crcontroller "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/controller"
        croperator "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/operator"
        $(fn_strings_to_lower ${CRKind})operator "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/operator/$(fn_strings_to_lower ${CRKind})"
        croperator "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/operator"

    )

    // controller is implement Controller for ${CRKind} resources
    type controller struct {
      crcontroller.Base
      register      prometheus.Registerer
      kubeClientSet kubeclientset.Interface
      crClientSet   crclientset.Interface
      queue         workqueue.RateLimitingInterface
      operator      croperator.Operator
      recorder record.EventRecorder

      serviceLister listercorev1.ServiceLister
      $(fn_strings_to_lower ${CRKind})Lister  crlister${GROUP_VERSION}.${CRKind}Lister
      cacheSynced cache.InformerSynced
    }


    // NewController create a new controller for ${CRKind} resources
    func NewController(kubeClientSet kubeclientset.Interface, kubeInformers informers.SharedInformerFactory, crClientSet crclientset.Interface,
      crInformers crinformers.SharedInformerFactory, reg prometheus.Registerer) crcontroller.Controller {
      eventBroadcaster := record.NewBroadcaster()
      eventBroadcaster.StartLogging(klog.V(2).Infof)
      eventBroadcaster.StartRecordingToSink(&typedcorev1.EventSinkImpl{Interface: kubeClientSet.CoreV1().Events(apicorev1.NamespaceAll)})
      recorder := eventBroadcaster.NewRecorder(scheme.Scheme, apicorev1.EventSource{Component: "${CRKind}-operator"})

      return new${CRKind}Controller(kubeClientSet, kubeInformers, crClientSet, crInformers, recorder, reg)
    }

    // new${CRKind}Controller is really
    func new${CRKind}Controller(kubeClientSet kubeclientset.Interface, kubeInformers informers.SharedInformerFactory, crClientSet crclientset.Interface,
      crInformers crinformers.SharedInformerFactory, recorder record.EventRecorder, reg prometheus.Registerer) *controller {
      c := &controller{
        register:      reg,
        kubeClientSet: kubeClientSet,
        crClientSet:   crClientSet,
        recorder:      recorder,
      }
      c.queue = workqueue.NewRateLimitingQueue(workqueue.DefaultControllerRateLimiter())

      $(fn_strings_to_lower ${CRKind})Informer := crInformers.${CRKind}operator().$(fn_strings_first_upper ${GROUP_VERSION})().${CRKind}s()
      c.$(fn_strings_to_lower ${CRKind})Lister = $(fn_strings_to_lower ${CRKind})Informer.Lister()
      $(fn_strings_to_lower ${CRKind})Informer.Informer().AddEventHandlerWithResyncPeriod(new${CRKind}EventHandler(c.queue.AddRateLimited, c.$(fn_strings_to_lower ${CRKind})Lister), 5*time.Second)

      c.cacheSynced = func() bool {
        return $(fn_strings_to_lower ${CRKind})Informer.Informer().HasSynced()
      }
      c.operator = $(fn_strings_to_lower ${CRKind})operator.NewOperator(c.kubeClientSet, c.crClientSet, c.$(fn_strings_to_lower ${CRKind})Lister,  c.recorder,c.register)
      return c
    }

    func (c *controller) Start(ctx context.Context) error {
      // wait for all involved cached to be synced , before processing items from the queue is started
      if !cache.WaitForCacheSync(ctx.Done(), c.cacheSynced) {
        return fmt.Errorf("timeout wait for cache to be synced")
      }
      klog.Info("Starting the workers of the $(fn_strings_to_lower ${CRKind}) controllers")
      go wait.Until(c.runWorker, time.Second, ctx.Done())
      return nil
    }

    // runWorker for loop
    func (c *controller) runWorker() {
      defer utilruntime.HandleCrash()
      for c.processNextItem() {}
    }

    func (c *controller) processNextItem() bool {
      key, quit := c.queue.Get()
      if quit {
        return false
      }
      defer func() {
        c.queue.Done(key)
        klog.Infof("Ending processing key: %d", key)
      }()
      klog.Infof("Starting process key: %q", key)
      if err := c.operator.Reconcile(key.(string)); err != nil {

        // There was a failure so be sure to report it. This method allows for plugable error handling
        // which can be used for things like cluster-monitoring
        utilruntime.HandleError(fmt.Errorf("failed to reconcile $(fn_strings_to_lower ${CRKind}) %q: %v", key, err))
        return true
      }
      // Successfully processed the key or the key was not found so tell the queue to stop tracking history for your key
      // This will reset things like failure counts for per-items rate limiting
      c.queue.Forget(key)
      return true
    }

    func (c *controller) Stop() {
      klog.Info("Stopping the $(fn_strings_to_lower ${CRKind}) operator controller")
      c.queue.ShutDown()
    }

    func (c *controller) enqueueFunc(obj interface{}) {
      key, err := cache.DeletionHandlingMetaNamespaceKeyFunc(obj)
      if err != nil {
        klog.Errorf("failed to get key for %v: %v", obj, err)
        return
      }
      c.queue.AddRateLimited(key)
    }
EOF
    gofmt -w pkg/controller/$(fn_strings_to_lower ${CRKind})/controller.go

    cat >> pkg/controller/$(fn_strings_to_lower ${CRKind})/collector.go << EOF
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
    package $(fn_strings_to_lower ${CRKind})
EOF
    gofmt -w pkg/controller/$(fn_strings_to_lower ${CRKind})/collector.go


    cat >> pkg/controller/$(fn_strings_to_lower ${CRKind})/handler.go << EOF
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

    package $(fn_strings_to_lower ${CRKind})

    import (
      crlister${GROUP_VERSION} "$(fn_project_to_gomod ${PROJECT_NAME})/pkg/client/listers/${GROUP_NAME}/${GROUP_VERSION}"
      listercorev1 "k8s.io/client-go/listers/core/v1"
      listterappsv1 "k8s.io/client-go/listers/apps/v1"
    )

    type $(fn_strings_to_lower ${CRKind})EventHandler struct {
      $(fn_strings_to_lower ${CRKind})Lister crlisterv1alpha1.LokiLister
      enqueueFn func(key interface{})
    }

    func (h *$(fn_strings_to_lower ${CRKind})EventHandler) OnAdd(obj interface{}) {
      panic("implement me")
    }

    func (h *$(fn_strings_to_lower ${CRKind})EventHandler) OnUpdate(oldObj, newObj interface{}) {
      panic("implement me")
    }

    func (h *$(fn_strings_to_lower ${CRKind})EventHandler) OnDelete(obj interface{}) {
      panic("implement me")
    }

    func new${CRKind}EventHandler(enqueueFn func(key interface{}), lister crlister${GROUP_VERSION}.${CRKind}Lister)*$(fn_strings_to_lower ${CRKind})EventHandler{
      return &$(fn_strings_to_lower ${CRKind})EventHandler{
        $(fn_strings_to_lower ${CRKind})Lister: lister,
        enqueueFn:    enqueueFn,
      }
    }
EOF
    gofmt -w pkg/controller/$(fn_strings_to_lower ${CRKind})/handler.go

    cat >> pkg/controller/$(fn_strings_to_lower ${CRKind})/informer.go << EOF
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

    package $(fn_strings_to_lower ${CRKind})
EOF
    gofmt -w pkg/controller/$(fn_strings_to_lower ${CRKind})/informer.go
}


##############################################################################
#                       Operator相关的部分                                  #
##############################################################################

function fn_gen_package_pkg_operator_interfaces(){
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    mkdir pkg/operator/
    cat >> pkg/operator/operator.go << EOF
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
    gofmt -w pkg/operator/operator.go

    cat >> pkg/operator/doc.go << EOF
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
    gofmt -w pkg/operator/doc.go
}

function fn_gen_package_pkg_operator_crdoperator() {
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    GROUP_NAME=$(fn_strings_to_lower ${2})
    GROUP_VERSION=$(fn_strings_to_lower ${3})
    RESOURCE_KIND=$(fn_strings_to_lower ${4})  # 资源类型
    CRKind=$(fn_strings_first_upper ${RESOURCE_KIND})    #CRKind 名称，首字母要大写

    mkdir -pv  pkg/operator/$(fn_strings_to_lower ${CRKind})

    cat >> pkg/operator/$(fn_strings_to_lower ${CRKind})/operator.go << EOF
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
    package ${RESOURCE_KIND}

    import (
      "fmt"

      "github.com/prometheus/client_golang/prometheus"
      k8serror "k8s.io/apimachinery/pkg/api/errors"
      utilruntime "k8s.io/apimachinery/pkg/util/runtime"
      "k8s.io/client-go/kubernetes"
      "k8s.io/client-go/tools/cache"
      "k8s.io/client-go/tools/record"

      crclientset "$(fn_project_to_gomod)/pkg/client/clientset/versioned"
      crlister${GROUP_VERSION} "$(fn_project_to_gomod)/pkg/client/listers/${GROUP_NAME}/${GROUP_VERSION}"
      croperator "$(fn_project_to_gomod)/pkg/operator"
    )

    type operator struct {
      $(fn_strings_to_lower ${CRKind})Client    crclientset.Interface
      kubeClientSet kubernetes.Interface
      recorder      record.EventRecorder
      $(fn_strings_to_lower ${CRKind})Lister    crlisterv1alpha1.LokiLister
      reg           prometheus.Registerer
    }

    func NewOperator(kubeClientSet kubernetes.Interface, crClient crclientset.Interface, $(fn_strings_to_lower ${CRKind})Lister crlisterv1alpha1.LokiLister, recorder record.EventRecorder, reg prometheus.Registerer) croperator.Operator {
      return &operator{
        crClient:    crClient,
        kubeClientSet: kubeClientSet,
        $(fn_strings_to_lower ${CRKind})Lister:    $(fn_strings_to_lower ${CRKind})Lister,
        reg:           reg,
      }
    }

    func (o *operator) Reconcile(object interface{}) error {
      namespace, name, err := cache.SplitMetaNamespaceKey(object.(string))
      if err != nil {
        utilruntime.HandleError(fmt.Errorf("failed to get the namespace and name from key: %v : %v", object, err))
        return nil
      }

      $(fn_strings_to_lower ${CRKind}), err := o.$(fn_strings_to_lower ${CRKind})Lister.${CRKind}s(namespace).Get(name)
      if err != nil {
        return handlerError(err)
      }
      _ = loki
      // write your code here
      return nil
    }

    func handlerError(err error) error {
      if k8serror.IsNotFound(err) {
        utilruntime.HandleError(err)
        return nil
      } else {
        return err
      }
    }

EOF
    gofmt -w pkg/operator/$(fn_strings_to_lower ${CRKind})/operator.go
}


# generate hackscripts
mkdir -pv ${PROJECT_NAME}/hack

function fn_gen_hack_script_docker() {
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    GOVERSION=$(go env GOVERSION)
    mkdir -pv hack/docker
    cat >> hack/docker/codegen.dockerfile << EOF
FROM golang:${GOVERSION//go/}

ENV GO111MODULE=auto
ENV GOPROXY="https://goproxy.cn"

RUN go get k8s.io/code-generator; exit 0
WORKDIR /go/src/k8s.io/code-generator
RUN go get -d ./...

RUN mkdir -p /go/src/$(fn_project_to_gomod)
VOLUME /go/src/$(fn_project_to_gomod)

WORKDIR /go/src/$(fn_project_to_gomod)
EOF
}
# create kubernetes builder images



function fn_gen_hack_tools_gofile() {
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    mkdir -pv hack/
    cat >> hack/tools.go << EOF
// +build tools

package tools

import _ "k8s.io/code-generator"
EOF
}


function fn_gen_hack_script_upgrade(){
    PROJECT_NAME=$(fn_strings_to_lower ${1})
    GROUP_NAME=$(fn_strings_to_lower ${2})
    GROUP_VERSION=$(fn_strings_to_lower ${3})
    mkdir -pv hack/scripts
    cat >> hack/scripts/codegen-update.sh << EOF
#!/usr/bin/env bash

CURRENT_DIR=\$(echo "\$(pwd)/\$line")
REPO_DIR="\$CURRENT_DIR"
IMAGE_NAME="kubernetes-codegen:latest"

echo "Building codgen Docker image ...."
docker build -f "\${CURRENT_DIR}/hack/docker/codegen.dockerfile" \\
             -t "\${IMAGE_NAME}" \\
             "\${REPO_DIR}" 
            

cmd="go mod tidy && /go/src/k8s.io/code-generator/generate-groups.sh  all  \\
        "$(fn_project_to_gomod)/pkg/client" \\
        "$(fn_project_to_gomod)/pkg/apis" \\
        ${GROUP_NAME}:${GROUP_VERSION} -h /go/src/k8s.io/code-generator/hack/boilerplate.go.txt"
    
echo "Generating client codes ...."

docker run --rm -v "\${REPO_DIR}:/go/src/$(fn_project_to_gomod)" \\
        "\${IMAGE_NAME}" /bin/bash -c "\${cmd}"
EOF
}

# 初始化项目
mkdir -pv ${PROJECT_NAME}/hack && cp $0 ${PROJECT_NAME}/hack/
cd ${PROJECT_NAME} && go mod init $(fn_project_to_gomod ${PROJECT_NAME})
# mkdir e2e test package
mkdir -pv e2e

## 生成相关的更新脚本文件
fn_gen_hack_tools_gofile ${PROJECT_NAME}
# 生成dockerfile文件
fn_gen_hack_script_docker ${PROJECT_NAME}
# 生成脚本文件
fn_gen_hack_script_upgrade ${PROJECT_NAME} ${GROUP_NAME} ${PROJECT_VERSION}


# 创建GVR 相关文件
# 开始执行
echo "Begin generate some necessary code file"
# 生成register.go文件
fn_gen_gofile_group_register ${PROJECT_NAME} ${GROUP_NAME}
# 生成group doc文件
fn_gen_gofile_group_version_doc ${PROJECT_NAME} ${GROUP_NAME} ${PROJECT_VERSION}
# 生成group types文件
fn_gen_gofile_group_version_types  ${PROJECT_NAME} ${GROUP_NAME} ${PROJECT_VERSION} ${CRKind}
# 生成 register文件
fn_gen_gofile_group_version_register ${PROJECT_NAME} ${GROUP_NAME} ${GROUP_VERSION} ${CRKind}
# 生成配置文件
fn_gen_gofile_install_install ${PROJECT_NAME} ${GROUP_NAME} ${GROUP_VERSION}
#
# 开始自动生成相关的代码
bash hack/scripts/codegen-update.sh
#
## cmd相关 main.go
fn_gen_gofile_cmd_project_main  ${PROJECT_NAME}
# signals.go
fn_gen_gofile_cmd_projct_signals ${PROJECT_NAME}
# start.go
fn_gen_gofile_cmd_project_startcmd ${PROJECT_NAME} ${GROUP_NAME} ${PROJECT_VERSION}
# options
fn_gen_gofile_cmd_project_options_interface ${PROJECT_NAME}
# /options
fn_gen_gofile_cmd_project_options_options ${PROJECT_NAME}
#

# controller package
fn_gen_gofile_pkg_controller_interfaces ${PROJECT_NAME}
# crdcontroller
fn_gen_package_pkg_controller_CRKind ${PROJECT_NAME} ${GROUP_NAME} ${GROUP_VERSION} ${CRKind}


#
# opetator
fn_gen_package_pkg_operator_interfaces ${PROJECT_NAME}
fn_gen_package_pkg_operator_crdoperator  ${PROJECT_NAME} ${GROUP_NAME} ${GROUP_VERSION} ${CRKind}


#
go mod tidy && go mod vendor
