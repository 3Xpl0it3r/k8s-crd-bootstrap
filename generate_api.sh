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
CRDKind=$(echo $(echo ${PROJECT_NAME}|awk -F'-' '{print $1}'|awk -F'_' '{print $1}')|awk '{print toupper(substr($0,1,1))substr($0,2)}')

if [ "${PROJECT_VERSION}" = "" ]
then
    PROJECT_VERSION="v1alpha1"
fi

if [ "${PROJECT_AUTHOR}" = "" ]
then
    PROJECT_AUTHOR="l0calh0st"
fi


function fn_project_module()
{
    echo "${GIT_DOMAIN}/${PROJECT_AUTHOR}/${PROJECT_NAME}"
}





# create project directory
mkdir -pv ${PROJECT_NAME}
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
            

generate_group="go mod tidy && /go/src/k8s.io/code-generator/generate-groups.sh  all  \\
        "$(fn_project_module)/pkg/client" \\
        "$(fn_project_module)/pkg/apis" \\
        ${GROUP_NAME}:${PROJECT_VERSION} -h /go/src/k8s.io/code-generator/hack/boilerplate.go.txt"
    
echo "Generating client codes ...."

docker run --rm -v "\${REPO_DIR}:/go/src/$(fn_project_module)" \\
        "\${IMAGE_NAME}" /bin/bash -c "\${generate_group}"


echo "Genetate internal codes ...."

generate_internal_group="go mod tidy && /go/src/k8s.io/code-generator/generate-internal-groups.sh  all  \\
        "$(fn_project_module)/pkg/client" \\
        "$(fn_project_module)/pkg/apis" \\
        "$(fn_project_module)/pkg/apis" \\
        ${GROUP_NAME}:${PROJECT_VERSION} -h /go/src/k8s.io/code-generator/hack/boilerplate.go.txt"

docker run --rm -v "\${REPO_DIR}:/go/src/$(fn_project_module)" \\
        "\${IMAGE_NAME}" /bin/bash -c "\${generate_internal_group}"



EOF

chmod +x ${PROJECT_NAME}/hack/codegen-update.sh


# crate apis package
mkdir -pv ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/${PROJECT_VERSION}
mkdir -pv ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/install ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/ 
mkdir -pv ${PROJECT_NAME}/pkg/client

# generate code for internal version
# generate doc.go
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/doc.go << EOF
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

// Package api is the internal version of the API.
package ${GROUP_PACKAGE_NAME}

EOF



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

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

const (
	GroupName = "${GROUP_NAME}"
)

var (
    SchemeGroupVersion = schema.GroupVersion{Group: GroupName, Version: runtime.APIVersionInternal,}
)


func Kind(kind string)schema.GroupKind{
	return SchemeGroupVersion.WithKind(kind).GroupKind()
}

func Resource(resource string)schema.GroupResource{
	return SchemeGroupVersion.WithResource(resource).GroupResource()
}

var (
	SchemeBuilder = runtime.NewSchemeBuilder(addKnownTypes)
	AddToScheme = SchemeBuilder.AddToScheme
)

func addKnownTypes(scheme *runtime.Scheme)error{
	scheme.AddKnownTypes(SchemeGroupVersion,
		new(${CRDKind}),
		new(${CRDKind}List),
	metav1.AddToGroupVersion(scheme, SchemeGroupVersion)
	return  nil
}

EOF

# generate types.go
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/types.go << EOF
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

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// ${CRDKind} defines ${CRDKind} deployment
type ${CRDKind} struct {
	metav1.TypeMeta
	metav1.ObjectMeta

	Spec FooSpec
}

type ${CRDKind}Spec struct {
	// +k8s:conversion-gen=false
    // todo write your code here

}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// ${CRDKind}List carries a list of ${CRDKind} objects
type ${CRDKind}List struct {
	metav1.TypeMeta
	metav1.ListMeta

	Items []${CRDKind}
}

EOF


# generate code for external version
EXTERNAL_VERSION=${PROJECT_VERSION}

# auto generate doc.go
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/${EXTERNAL_VERSION}/doc.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, EXTERNAL_VERSION 2.0 (the "License");
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

// Package ${EXTERNAL_VERSION} is the ${EXTERNAL_VERSION} version of the API.
package ${EXTERNAL_VERSION} // import "$(fn_project_module)/pkg/apis/${GROUP_NAME}/${EXTERNAL_VERSION}"


EOF

# auto geneate types.go
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/${EXTERNAL_VERSION}/types.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, EXTERNAL_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


package ${EXTERNAL_VERSION}

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)


// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +k8s:defaulter-gen=true

// ${CRDKind} defines ${CRDKind} deployment
type ${CRDKind} struct {
	metav1.TypeMeta \`json:",inline"\`
	metav1.ObjectMeta \`json:"metadata,omitempty" protobuf:"bytes,1,opt,name=metadata"\`

	Spec ${CRDKind}Spec \`json:"spec" protobuf:"bytes,2, opt,name=spec"\`
	Status ${CRDKind}Status \`json:"status" protobuf="bytes,3,opt,name=status"\`
}


// ${CRDKind}Spec describes the specification of ${CRDKind} applications using kubernetes as a cluster manager
type ${CRDKind}Spec struct {
    // todo, write your code
}

// ${CRDKind}Status describes the current status of ${CRDKind} applications
type ${CRDKind}Status struct {
    // todo, write your code
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// ${CRDKind}List carries a list of ${CRDKind} objects
type ${CRDKind}List struct {
	metav1.TypeMeta \`json:",inline"\`
	metav1.ListMeta \`json:"metadata,omitempty" protobuf:"bytes,1,opt,name=metadata"\`

	Items []$CRDKind \`json:"items" protobuf:"bytes,2,rep,name=items"\`
}
EOF

# generate regiser.go
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/${EXTERNAL_VERSION}/register.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, EXTERNAL_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package ${EXTERNAL_VERSION}

import (
    "$(fn_project_module)/pkg/apis/${GROUP_NAME}"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

const (
    Version = "${EXTERNAL_VERSION}"
)

var (
    // SchemeBuilder initializes a scheme builder
	SchemeBuilder = runtime.NewSchemeBuilder(addKnowTypes)
    // AddToScheme is a global function that registers this API group & version to a scheme
	AddToScheme = SchemeBuilder.AddToScheme
)

var (
    // SchemeGroupEXTERNAL_VERSION is group version used to register these objects
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
		new(${CRDKind}),
        new(${CRDKind}List),)
	metav1.AddToGroupVersion(scheme, SchemeGroupVersion)
	return nil
}
EOF

# generate defaults code
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/${EXTERNAL_VERSION}/defaults.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, EXTERNAL_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package ${EXTERNAL_VERSION}

import "k8s.io/apimachinery/pkg/runtime"

func addDefaultingFuncs(scheme *runtime.Scheme) error {
	return RegisterDefaults(scheme)
}


// SetDefaults_${CRDKind}Spec
func SetDefaults_${CRDKind}Spec(obj *${CRDKind}Spec) {
    // write your defaults code here
}

EOF


# generate conversion code
cat >> ${PROJECT_NAME}/pkg/apis/${GROUP_NAME}/${EXTERNAL_VERSION}/conversion.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, EXTERNAL_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package ${EXTERNAL_VERSION}

import (
    "$(fn_project_module)/pkg/apis/${GROUP_NAME}"
	"k8s.io/apimachinery/pkg/conversion"
)


// Convert_${EXTERNAL_VERSION}_${CRDKind}Spec_To_${GROUP_NAME}_${CRDKind}Spec
func Convert_${EXTERNAL_VERSION}_${CRDKind}Spec_To_${GROUP_NAME}_${CRDKind}Spec(in *${CRDKind}Spec, out *${GROUP_NAME}.${CRDKind}Spec, s conversion.Scope) error {
    // write your conversion code here
	return nil
}

// Convert_${GROUP_NAME}_${CRDKind}Spec_To_${EXTERNAL_VERSION}_${CRDKind}Spec
func Convert_${GROUP_NAME}_${CRDKind}Spec_To_${EXTERNAL_VERSION}_${CRDKind}Spec(in *${GROUP_NAME}.${CRDKind}Spec, out *${CRDKind}Spec, s conversion.Scope) error {
    // write your coveersion code here
	return nil
}

// Convert_${EXTERNAL_VERSION}_${CRDKind}Status_To_${GROUP_NAME}_${CRDKind}Status
func Convert_${EXTERNAL_VERSION}_${CRDKind}Status_To_${GROUP_NAME}_${CRDKind}Status(in *${CRDKind}Status, out *${GROUP_NAME}.${CRDKind}Status, s conversion.Scope) error {
    // write your conversion code here
	return nil
}

// Convert_${GROUP_NAME}_${CRDKind}Status_To_${EXTERNAL_VERSION}_${CRDKind}Status
func Convert_${GROUP_NAME}_${CRDKind}Status_To_${EXTERNAL_VERSION}_${CRDKind}Status(in *${GROUP_NAME}.${CRDKind}Status, out *${CRDKind}Status, s conversion.Scope) error {
    // write your coveersion code here
	return nil
}
EOF


# generate admission code
# create admission package
mkdir -pv ${PROJECT_NAME}/pkg/admission
mkdir -pv ${PROJECT_NAME}/pkg/admission/initializer 
# generate admission interface
cat >> ${PROJECT_NAME}/pkg/admission/initializer/interfaces.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, EXTERNAL_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package initializer

import (
    crexternalinformers "$(fn_project_module)/pkg/client/informers/externalversions"
	"k8s.io/apiserver/pkg/admission"
)

type WantInternal${GROUP_PACKAGE_NAME}InformerFactory interface {
	SetInternalBazInformerFactory(factory informers.SharedInformerFactory)
	admission.InitializationValidator
}
EOF

cat >> ${PROJECT_NAME}/pkg/admission/initializer/${GROUP_PACKAGE_NAME}initializer.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, EXTERNAL_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package initializer

import (
    crexternalinformers "$(fn_project_module)/pkg/client/informers/externalversions"
	"k8s.io/apiserver/pkg/admission"
)

type pluginInitializer struct {
	informers crexternalinformers.SharedInformerFactory
}


var _ admission.PluginInitializer = pluginInitializer{}

func (p pluginInitializer) Initialize(plugin admission.Interface) {
	if wants, ok := plugin.(WantInternal${GROUP_PACKAGE_NAME}InformerFactory); ok {
		wants.SetInternalBazInformerFactory(p.informers)
	}
}


func New(informers crexternalinformers.SharedInformerFactory) pluginInitializer {
	return pluginInitializer{informers: informers}
}
EOF
# generate admission plugins
mkdir ${PROJECT_NAME}/pkg/admission/plugin/${CRDKind}
cat >> ${PROJECT_NAME}/pkg/admission/plugin/${CRDKind}/admission.go << EOF
/*
Copyright `date "+%Y"` The ${PROJECT_NAME} Authors.
Licensed under the Apache License, EXTERNAL_VERSION 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package foo

import (
	"io"
	"fmt"
	"context"

    "$(fn_project_module)/pkg/admission/initializer"
    ${GROUP_PACKAGE_NAME}apis "$(fn_project_module)/pkg/apis/${GROUP_NAME}"
    crexternalinformers "$(fn_project_module)/pkg/client/informers/externalversions"
    ${GROUP_PACKAGE_NAME}${EXTERNAL_VERSION} "$(fn_project_module)/pkg/client/listers/${GROUP_NAME}/${EXTERNAL_VERSION}"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apiserver/pkg/admission"
)


// Register register a plugin
func Register(plugins *admission.Plugins){
	plugins.Register("${CRDKind}", func(config io.Reader) (admission.Interface, error) {
		return New()
	})
}

// Plugin represent specification a plugin
type Plugin struct {
	*admission.Handler
	${GROUP_PACKAGE_NAME}Lister ${GROUP_PACKAGE_NAME}${EXTERNAL_VERSION}.${CRDKind}Lister
}


// New Create a new admission plugins
func New()(*Plugin, error){
	return &Plugin{
		Handler:   admission.NewHandler(admission.Create, admission.Update),
	}, nil
}

var _ initializer.WantInternal${GROUP_PACKAGE_NAME}InformerFactory = &Plugin{}

// Admin ensures that object in-flight 	is of kind ${CRDKind}
// In addition checks that the Name is not on the banned list
// The list is stored in Fischers API objects
func (p *Plugin)Admin(ctx context.Context, a admission.Attributes, oi admission.ObjectInterfaces)error{
	if a.GetKind().GroupKind() != ${GROUP_PACKAGE_NAME}apis.Kind("${CRDKind}") {
		return nil
	}
	if !p.WaitForReady(){
		return admission.NewForbidden(a, fmt.Errorf("not yet ready to handle request"))
	}
	obj := a.GetObject()
    _ = obj
    // write your custom code here
	return nil
}

func (d *Plugin) Validate(a admission.Attributes, o admission.ObjectInterfaces, ) error {
	if a.GetKind().GroupKind() != ${GROUP_PACKAGE_NAME}apis.Kind("${CRDKind}") {
		return nil
	}
    // write your custom code here
	return nil
}

func (p *Plugin) SetInternalBazInformerFactory(factory crexternalinformers.SharedInformerFactory) {
	p.barLister = factory.Baz().V1alpha1().Bars().Lister()
	p.SetReadyFunc(factory.Baz().V1alpha1().Bars().Informer().HasSynced)
}

func (p *Plugin) ValidateInitialization() error {
	if p.barLister == nil{
		return fmt.Errorf("Foo plugin missing Foos policy lister ")
	}
	return nil
}

EOF


# create apiserver package
mkdir -pv ${PROJECT_NAME}/pkg/apiserver

# create registry package
mkdir -pv ${PROJECT_NAME}/pkg/registry/${GROUP_NAME}/${CRDKind}

# init go mod
cd ${PROJECT_NAME} && go mod init $(fn_project_module)  && go mod tidy && go mod vendor
