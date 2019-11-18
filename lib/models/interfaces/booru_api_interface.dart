/*  Provide base link
    *My account
    *Logging In
    Create post
    Update post
    Destroy post
    Revert tags
    *Vote post
    Tags
    Artists - artists page
    *Comments
    Wiki
    Notes
    Search users
    Favorites
*/

// Interface for booru client
abstract class BooruClient {
  // Client base url
  String getBaseUrl();

  // Login to the booru
  void login();

  // Vote a post
  void votePost(int postID);


}
