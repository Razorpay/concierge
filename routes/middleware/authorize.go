package middleware

import (
	"concierge/database"
	"concierge/models"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
)

//Authorize ...
func Authorize(c *gin.Context) {
	// Disable user groups and enable user email
	if database.DB == nil {
		database.Conn()
	}
	username := c.GetHeader("X-Forwarded-User")
	email := c.GetHeader("X-Forwarded-Email")
	split := strings.Split(email, "@")
	if split[1] != os.Getenv("COMPANY_DOMAIN") {
		c.AbortWithStatusJSON(404, "Invalid Organization Email")
		return
	}
	user := models.Users{
		Email: email,
	}
	getUser := &models.Users{}
	database.DB.FirstOrCreate(getUser, user)
	getUser.Username = username
	getUser.Name = username
	database.DB.Model(&models.Users{}).Updates(getUser)
	c.Set("User", getUser)
	c.Next()
}