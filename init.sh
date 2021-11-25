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

# ProjectName is directory of project
ProjectName=$1
Version=$2
Author=$3


ProjectAddress="github.com/$Author/$ProjectName"
# exampleoperator.l0calh0st.cn
GroupName=$(echo $ProjectName|sed 's/-//'|sed 's/_//').$Author.cn
# exampleoperator
GroupNameForShort=$(echo $ProjectName|sed 's/-//'|sed 's/_//')

# CRD type
CrdType=`echo $(echo $ProjectName|awk -F'-' '{print $1}'|awk -F'_' '{print $1}')|awk '{print toupper(substr($0,1,1))substr($0,2)}'`
CrdSpec=$CrdType"Spec"
CrdStatus=$CrdType"Status"
CrdList=$CrdType"List"

if [ "$Version" = "" ]
then
    Version="v1alpha1"
fi

if [ "$Author" = "" ]
then
    Author="l0calh0st"
fi


function mod_name()
{
    echo "github.con/$Author/$Project"
}

# create project directory
mkdir -pv $ProjectName
mkdir -pv $ProjectName/hack
mkdir -pv $ProjectName/pkg/apis/$GroupName/$Version
mkdir -pv $ProjectName/pkg/client


# create boilerplate.go.txt tools.go update-group.sh
cat >> $ProjectName/hack/boilerplate.go.txt << EOF
/*
Copyright The $ProjectName Authors.
*/
EOF

cat >> $ProjectName/hack/tools.go << EOF
// +build tools

package tools

import _ "k8s.io/code-generator"
EOF


cat >> $ProjectName/hack/update-group.sh << EOF
#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

(
  # To support running this script from anywhere, we have to first cd into this directory
  # so we can install the tools.
  cd "\$(dirname "\${0}")"/../vendor/k8s.io/code-generator/
  go install ./cmd/{defaulter-gen,client-gen,lister-gen,informer-gen,deepcopy-gen}
)
# Go installs the above commands to get installed in $GOBIN if defined, and $GOPATH/bin otherwise:
GOBIN="$(go env GOBIN)"
gobin="${GOBIN:-$(go env GOPATH)/bin}"

echo "Generating deepcopy funcs"
"\${gobin}/deepcopy-gen" -O zz_generated.deepcopy  --go-header-file ./boilerplate.go.txt --bounding-dirs ../pkg/apis/$GroupName/$Version --input-dirs ../pkg/apis/$GroupName/$Version --output-base ./ 

echo "Generating clientset for $GroupName "
"\${gobin}/client-gen" --clientset-name versioned --go-header-file ./boilerplate.go.txt   --input-base "$ProjectAddress" --input "$GroupName/$Version" --input-dirs ../pkg/apis/$GroupName/$Version --output-base ../  --output-package pkg/client/clientset 


echo "Generating listers for $GroupName "
"\${gobin}/lister-gen" --go-header-file ./boilerplate.go.txt --input-dirs  ../pkg/apis/$GroupName/$Version --output-base ../  --output-package pkg/client/listers


echo "Generating informers for $GroupName "
"\${gobin}/informer-gen" --go-header-file ./boilerplate.go.txt --input-dirs ../pkg/apis/$GroupName/$Version --output-package pkg/client/informers --output-base ../  --listers-package ../pkg/client/listers --versioned-clientset-package ../pkg/client/clientset/versioned 


EOF

chmod +x $ProjectName/hack/update-group.sh

# create apis

# auto generate regisgter.go file
cat >> $ProjectName/pkg/apis/$GroupName/register.go << EOF
/*
Copyright `date "+%Y"` The $ProjectName Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package $GroupNameForShort

const (
	GroupName = "$GroupName"
)
EOF

# auto generate doc.go
cat >> $ProjectName/pkg/apis/$GroupName/$Version/doc.go << EOF
/*
Copyright `date "+%Y"` The $ProjectName Authors.
Licensed under the Apache License, Version 2.0 (the "License");
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
// +groupName=$GroupName

// Package $Version is the $Version version of the API.
package $Version // import "$ProjectAddress/pkg/apis/$GroupName/$Version"


EOF

# auto geneate types.go
cat >> $ProjectName/pkg/apis/$GroupName/$Version/types.go << EOF
/*
Copyright `date "+%Y"` The $ProjectName Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


package $Version

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)


// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +k8s:defaulter-gen=true

// $CrdType defines $CrdType deployment
type $CrdType struct {
	metav1.TypeMeta \`json:",inline"\`
	metav1.ObjectMeta \`json:"metadata,omitempty"\`

	Spec $CrdSpec \`json:"spec"\`
	Status $CrdStatus \`json:"status"\`
}


// $CrdSpec describes the specification of $CrdType applications using kubernetes as a cluster manager
type $CrdSpec struct {
    // todo, write your code
}

// $CrdStatus describes the current status of $CrdType applications
type $CrdStatus struct {
    // todo, write your code
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// $CrdList carries a list of $CrdType objects
type $CrdList struct {
	metav1.TypeMeta \`json:",inline"\`
	metav1.ListMeta \`json:"metadata,omitempty"\`

	Items []$CrdType \`json:"items"\`
}
EOF

# generate regiser.go
cat >> $ProjectName/pkg/apis/$GroupName/$Version/register.go << EOF
/*
Copyright `date "+%Y"` The $ProjectName Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package $Version

import (
    "$ProjectAddress/pkg/apis/$GroupName"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

const (
    Version = "$Version"
)

var (
    // SchemeBuilder initializes a scheme builder
	SchemeBuilder = runtime.NewSchemeBuilder(addKnowTypes)
    // AddToScheme is a global function that registers this API group & version to a scheme
	AddToScheme = SchemeBuilder.AddToScheme
)

var (
    // SchemeGroupVersion is group version used to register these objects
	SchemeGroupVersion = schema.GroupVersion{Group:  $GroupNameForShort.GroupName, Version: Version}
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
		new($CrdType),
        new($CrdList),)
	metav1.AddToGroupVersion(scheme, SchemeGroupVersion)
	return nil
}
EOF

# go mod vendor
export GOPROXY=https://goproxy.cn 


# init go mod
cd $ProjectName && go mod init  $ProjectAddress  && go mod tidy && go mod vendor
cd hack &&  bash update-group.sh
