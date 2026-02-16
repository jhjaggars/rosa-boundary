/**
 * Keycloak JavaScript Protocol Mapper for AWS Session Tags
 *
 * This script creates the nested JSON structure required by AWS STS
 * for session tags with AssumeRoleWithWebIdentity.
 *
 * AWS expects session tags in this format:
 * {
 *   "https://aws.amazon.com/tags": {
 *     "principal_tags": {
 *       "tagKey": ["value1", "value2"]
 *     }
 *   }
 * }
 *
 * This mapper extracts user group membership and creates the structure.
 */

// Get user's groups
var groups = [];
var userGroups = user.getGroupsStream().toArray();

for (var i = 0; i < userGroups.length; i++) {
    groups.push(userGroups[i].getName());
}

// Create AWS session tags structure
var awsTags = {
    "principal_tags": {
        "groups": groups
    }
};

// Export the structured tags
// This will be added to the token under the claim name specified in the mapper config
exports = awsTags;
