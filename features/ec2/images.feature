# Copyright 2011 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

# language: en
@ec2 @images
Feature: Basic Image Operations

  As a user of the high-level interface for EC2
  I want to create, list, and deregister images
  So that I can make my instances repeatable.

  @slow
  Scenario: Create EBS-backed image
    Given I request to run an instance with the following parameters:
    | parameter | value        |
    | image_id  | ami-8c1fece5 |
    And I wait for the instance status to be "running"
    When I create an image from the instance with the following parameters:
    | parameter   | value               |
    | name        | my-image            |
    | description | the one I just made |
    | no_reboot   | true                |
    Then the result should be an image
    And the image should eventually be in the list of images I own
    And a request should have been made like:
    | TYPE        | NAME        | VALUE               |
    | param       | Action      | CreateImage         |
    | param_match | InstanceId  | i-.+                |
    | param       | Name        | my-image            |
    | param       | Description | the one I just made |
    | param       | NoReboot    | true                |

  Scenario: Register S3-backed image
    When I create an image with the following parameters:
    | parameter      | value                                      |
    | name           | my-image                                   |
    | description    | the s3-backed one I just made              |
    | image_location | aws-sdk-amis/quickstart/image.manifest.xml |
    | architecture   | i386                                       |
    | kernel_id      | aki-12f0127b                               |
    | ramdisk_id     | ari-0ccd3965                               |
    Then the result should be an image
    And a request should have been made like:
    | TYPE  | NAME          | VALUE                                      |
    | param | Action        | RegisterImage                              |
    | param | ImageLocation | aws-sdk-amis/quickstart/image.manifest.xml |
    | param | Name          | my-image                                   |
    | param | Description   | the s3-backed one I just made              |
    | param | Architecture  | i386                                       |
    | param | KernelId      | aki-12f0127b                               |
    | param | RamdiskId     | ari-0ccd3965                               |

  Scenario: List images
    Given I create an image with the following parameters:
    | parameter      | value                                      |
    | name           | my-image                                   |
    | image_location | aws-sdk-amis/quickstart/image.manifest.xml |
    When I ask for the list of images owned by me
    Then the image I created should be in the list
    And a request should have been made like:
    | TYPE  | NAME    | VALUE          |
    | param | Action  | DescribeImages |
    | param | Owner.1 | self           |

  @memoized
  Scenario: List images with memoization
    Given I start a memoization block
    When I compute a hash of image name to image ID for Amazon-owned images
    And I sort the list of Amazon-owned images by image location
    Then exactly 1 request should have been made like:
    | TYPE  | NAME   | VALUE          |
    | param | Action | DescribeImages |

  @memoized
  Scenario: List image EBS information with memoization
    Given I start a memoization block
    When I compute a hash of mapped snapshot ID to image ID for Amazon-owned images
    Then exactly 1 request should have been made like:
    | TYPE  | NAME   | VALUE          |
    | param | Action | DescribeImages |
    And no requests should have been made like:
    | TYPE  | NAME   | VALUE                  |
    | param | Action | DescribeImageAttribute |

  Scenario: Deregister image
    Given I create an image with the following parameters:
    | parameter      | value                                      |
    | name           | my-image                                   |
    | image_location | aws-sdk-amis/quickstart/image.manifest.xml |
    When I deregister the image
    Then the image should eventually not exist
    And a request should have been made like:
    | TYPE        | NAME    | VALUE           |
    | param       | Action  | DeregisterImage |
    | param_match | ImageId | ami-.+          |

  Scenario: Get image by ID
    When I ask for the image "ami-123" by ID
    Then the result should be an image

  Scenario: Check that an image exists (does not exist)
    Given I ask for the image "ami-123" by ID
    When I ask if the image exists
    Then the result should be false

  Scenario: Check that an image exists (exists)
    Given I create an image with the following parameters:
    | parameter      | value                                      |
    | name           | my-image                                   |
    | image_location | aws-sdk-amis/quickstart/image.manifest.xml |
    When I ask if the image exists
    Then the result should eventually be true
