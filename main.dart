Wsdl database connection
  package server;

import java.sql.*;
import javax.jws.WebService;
import javax.jws.WebMethod;

@WebService(serviceName = "Curry_server")
public class Curry_server {

    public double getRate(String name) {

        double rate = 0;

        try {

            Connection con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/currency_db","root","");

            PreparedStatement ps = con.prepareStatement(
            "SELECT rate FROM currency WHERE name=?");

            ps.setString(1, name);

            ResultSet rs = ps.executeQuery();
            rs.next();

            rate = rs.getDouble("rate");

        } catch(Exception e) {
            System.out.println(e);
        }

        return rate;
    }

    @WebMethod
    public double rupeeToDollar(double rupee) {
        return rupee * getRate("Dollar");
    }

    @WebMethod
    public double rupeeToEuro(double rupee) {
        return rupee * getRate("Euro");
    }
}
