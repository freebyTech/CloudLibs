@Library('freebyTech')_

import com.freebyTech.BuildInfo

String versionPrefix = '1.0'
String repository = 'freebytech'    
String imageName = 'fbt-web-sandboxapp'
String dockerBuildArguments = ''
BuildInfo buildInfo

node 
{
  buildInfo = build(this, versionPrefix, repository, imageName, dockerBuildArguments, true, true)

  getApproval(imageName, 'None\nproduction')

  if(!'None'.equalsIgnoreCase(env.NAMESPACE)) 
  {
    deploy(buildInfo, repository, imageName)
  }
}

